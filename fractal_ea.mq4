#property copyright "Copyright 2018, zenott"
#property version   "1.0"
#property strict

// Expert initialization function                                   

extern double sl_atr_szorzo=0.5;
extern double tp_atr_szorzo=10;
extern double risk=100;
extern int kezdo_ora=8;
extern int veg_ora=19;
extern int torlo_ora=21;
extern int ma_period=35;
extern int atr_period=20;
extern int tp=4000;
extern int sl=100;
extern int trailingstep=20;
extern int trailingstart=40;
extern int orderpricebuffer=4;
extern bool dont_use_ma=false;
extern bool atr_stop=true;
extern bool st_trail=true;
extern bool par_trail=false;
extern int magic_number=12481632;

double up_price=0;
double down_price=0;
bool up_open=false;
bool down_open=false;
int up_ticket=0;
int down_ticket=0;
datetime time_bill=0;
datetime time_bill_m1=0;

double buy_pending_price[5]={0,0,0,0,0};
double sell_pending_price[5]={0,0,0,0,0};
int buy_pending_count[5]={0,0,0,0,0};
int sell_pending_count[5]={0,0,0,0,0};

void torles(){
   for(int i=OrdersTotal() - 1;i>=0; i--) {
      bool os=OrderSelect(i,SELECT_BY_POS);
      if (OrderSymbol()==Symbol() && (OrderType()==OP_SELLSTOP||OrderType()==OP_BUYSTOP)){
         bool del=OrderDelete(OrderTicket());
         if(!del) Print("#"+OrderTicket()+" Error deleting. Error code=",GetLastError());
         else Print("#"+OrderTicket()+" Order deleted.");
      }
   }
}

int OnInit(){
   ObjectCreate("sor_1",OBJ_LABEL,0,0,0);
   ObjectCreate("sor_2",OBJ_LABEL,0,0,0);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason){
   ObjectDelete("sor_1");
   ObjectDelete("sor_2");
   for(int i=0;i<=4; i++){
      ObjectDelete("buy_pending"+IntegerToString(i,1));
      ObjectDelete("sell_pending"+IntegerToString(i,1));
   }
}
  
void OnTick(){
     
   if (time_bill != Time[0]){
         double fractal_up=iFractals(NULL,0,MODE_UPPER,3);
         double fractal_down=iFractals(NULL,0,MODE_LOWER,3);
         
         
         if(fractal_up>0) {
               up_open=true;
               up_price=fractal_up+(orderpricebuffer+MarketInfo(Symbol(),MODE_SPREAD))*Point;
            } 
         if(fractal_down>0) {
               down_open=true;
               down_price=fractal_down-orderpricebuffer*Point;
            }
            
         bool uptrend;
         if(Bid>iMA(NULL,0,ma_period,0,MODE_SMMA,PRICE_CLOSE,0)) uptrend=true;
         else uptrend=false;
         
         bool in_time=false;
         if ((TimeHour(TimeCurrent())>=kezdo_ora) && (TimeHour(TimeCurrent())<=veg_ora)) in_time=true;
         
         if(TimeHour(TimeCurrent())==torlo_ora){
            for(int i=0;i<=4; i++){
               buy_pending_price[i]=0;
            }
            for(int i=0;i<=4; i++){
               sell_pending_price[i]=0;
            }
            Print("Pending order(s) deleted.");
         }
         
         
         
         if(up_open==true&&(uptrend==true||dont_use_ma)&&in_time==true){
            for(int i=0;i<=4; i++){
               if(buy_pending_price[i]==0) {
                  buy_pending_price[i]=up_price;
                  Print("A pending buy order "+i+" placed at "+up_price);
                  break;
               }
            }
         }
         
         if(down_open==true&&(uptrend==false||dont_use_ma)&&in_time==true){
            for(int i=0;i<=4; i++){
               if(sell_pending_price[i]==0) {
                  sell_pending_price[i]=down_price;
                  Print("A pending sell order "+i+" placed at "+down_price);
                  break;
               }
            }
         }
         
         ObjectSet("sor_1",OBJPROP_CORNER,2);
         ObjectSet("sor_1",OBJPROP_XDISTANCE,5);
         ObjectSet("sor_1",OBJPROP_YDISTANCE,14);
         ObjectSet("sor_1",OBJPROP_COLOR,Red);
         ObjectSet("sor_1",OBJPROP_WIDTH,3);
         ObjectSet("sor_1",OBJPROP_BACK,false);
         ObjectSet("sor_1",OBJPROP_FONTSIZE,10);
         ObjectSetText("sor_1",DoubleToStr(fractal_up,Digits)+"|"+DoubleToStr(fractal_down,Digits)+"|"+up_open+"|"+down_open,10,"Times New Roman");   
         
         up_open=false;
         up_price=0;  
         down_open=false;
         down_price=0;   
      }
   time_bill = Time[0]; 
   
   if (st_trail==false && par_trail==false){
      for(int pos=0;pos<OrdersTotal();pos++) {
      if (OrderSelect(pos,SELECT_BY_POS)==false) continue;
         if (OrderType()==OP_BUY && OrderSymbol()==Symbol() && OrderMagicNumber()==magic_number){
            int n;
            if ((Bid-OrderOpenPrice())<0) n=0; 
            else n=MathFloor(((Bid-OrderOpenPrice())/Point)/trailingstep);
            if ((Bid>OrderOpenPrice()+trailingstart*Point)&&(OrderStopLoss()+Point<OrderOpenPrice()+(n-1)*trailingstep*Point)){
               bool res=OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(OrderOpenPrice()+(n-1)*trailingstep*Point,Digits),OrderTakeProfit(),0,Blue);
               if(!res) Print("#"+OrderTicket()+" Error in OrderModify. Error code=",GetLastError());
               else Print("#"+OrderTicket()+" order sl modified successfully."); 
            }
         }
         
         if (OrderType()==OP_SELL && OrderSymbol()==Symbol() && OrderMagicNumber()==magic_number){
            int n;
            if ((OrderOpenPrice()-Ask)<0) n=0; 
            else n=MathFloor(((OrderOpenPrice()-Ask)/Point)/trailingstep);
            if ((Ask<OrderOpenPrice()-trailingstart*Point)&&(OrderStopLoss()-Point>OrderOpenPrice()-(n-1)*trailingstep*Point)){
               bool res=OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(OrderOpenPrice()-(n-1)*trailingstep*Point,Digits),OrderTakeProfit(),0,Blue);
               if(!res) Print("#"+OrderTicket()+" Error in OrderModify. Error code=",GetLastError());
               else Print("#"+OrderTicket()+" order sl modified successfully."); 
            }
         }
      }
   }
   
   for(int i=0;i<=4; i++){
      if (Ask>=buy_pending_price[i] && Ask<=buy_pending_price[i]+10*Point && buy_pending_price[i]!=0 && MarketInfo(Symbol(),MODE_SPREAD)<13){
         double atr=iATR(NULL,PERIOD_D1,atr_period,0);
         double tav;
         if(atr_stop==true) tav=(sl_atr_szorzo*atr)/Point;
         else tav=sl;
         double kezdolot=(risk)/(tav*MarketInfo(Symbol(),MODE_TICKVALUE));
         
         int up_ticket_1=OrderSend(Symbol(),OP_BUY,NormalizeDouble(kezdolot,2),Ask,7,NormalizeDouble(Ask-tav*Point,Digits),NormalizeDouble(Ask+tp*Point,Digits),IntegerToString(magic_number),magic_number,0,Green);
         if(up_ticket_1<=0) Print("#"+OrderTicket()+" at "+Ask+", Error = ",GetLastError());
         else Print("#"+OrderTicket()+" at "+Ask+" opened");
         buy_pending_price[i]=0;
      }  
      if(Ask>=buy_pending_price[i] && buy_pending_price[i]!=0){
         if (buy_pending_count[i]<=10) {
            buy_pending_count[i]++;
            Print("Could not open buy order "+i+" at "+buy_pending_price[i]+", count: "+buy_pending_count[i]+", Bid: "+Bid+", Ask: "+Ask+", Spread: "+MarketInfo(Symbol(),MODE_SPREAD));
         }
         else {
            buy_pending_price[i]=0;
            buy_pending_count[i]=0;
            Print("Could not open buy order "+i+" at "+buy_pending_price[i]+" in 10 attempts, Bid: "+Bid+", Ask: "+Ask+", Spread: "+MarketInfo(Symbol(),MODE_SPREAD));
         }
      }
      
      if (Bid<=sell_pending_price[i] && Bid>=sell_pending_price[i]-10*Point && sell_pending_price[i]!=0 && MarketInfo(Symbol(),MODE_SPREAD)<13){
         double atr=iATR(NULL,PERIOD_D1,atr_period,0);
         double tav;
         if(atr_stop==true) tav=(sl_atr_szorzo*atr)/Point;
         else tav=sl;
         double kezdolot=(risk)/(tav*MarketInfo(Symbol(),MODE_TICKVALUE));
         int down_ticket_1=OrderSend(Symbol(),OP_SELL,NormalizeDouble(kezdolot,2),Bid,7,NormalizeDouble(Bid+tav*Point,Digits),NormalizeDouble(Bid-tp*Point,Digits),IntegerToString(magic_number),magic_number,0,Green);
         if(down_ticket_1<=0) Print("#"+OrderTicket()+" at "+Bid+", Error = ",GetLastError());
         else Print("#"+OrderTicket()+" at "+Bid+" opened");
         sell_pending_price[i]=0;
      } 
      if(Bid<=sell_pending_price[i] && sell_pending_price[i]!=0){
         if (sell_pending_count[i]<=10) {
            sell_pending_count[i]++;
            Print("Could not open sell order "+i+" at "+sell_pending_price[i]+", count: "+sell_pending_count[i]+", Bid: "+Bid+", Ask: "+Ask+", Spread: "+MarketInfo(Symbol(),MODE_SPREAD));
         }
         else {
            sell_pending_price[i]=0;
            sell_pending_count[i]=0;
            Print("Could not open sell order "+i+" at "+sell_pending_price[i]+" in 10 attempts, Bid: "+Bid+", Ask: "+Ask+", Spread: "+MarketInfo(Symbol(),MODE_SPREAD));
         }
      }
   }

//supertrend trailing

   double StGreen;
   double StRed;
   
   
   if (st_trail==true){
      if(time_bill_m1!=iTime(NULL,PERIOD_M1,0)){
      
         
         
         StGreen = iCustom(NULL,PERIOD_M1,"xSuperTrendx",2,1);
         StRed = iCustom(NULL,PERIOD_M1,"xSuperTrendx",1,1);
                 
         
         for(int i=OrdersTotal() - 1;i>=0; i--) {
            bool os=OrderSelect(i,SELECT_BY_POS);
            
               
               
            if (StGreen>OrderOpenPrice() && StGreen!=EMPTY_VALUE){
                 if(OrderSymbol()==Symbol() && OrderMagicNumber()==magic_number && OrderType()==OP_BUY && (OrderStopLoss()<0.99999*StGreen)) {
                        bool mod=OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(StGreen,Digits),OrderTakeProfit(),0,Blue);
                        if (mod==true) Print ("#"+OrderTicket()+" sl modified to "+StGreen+" (Supertrend)");
                           else Print("Error = ",GetLastError());
                 } 
            }
         
               
            if ((OrderOpenPrice()>StRed) && StRed!=EMPTY_VALUE){
                 if(OrderSymbol()==Symbol() && OrderMagicNumber()==magic_number  && OrderType()==OP_SELL && (OrderStopLoss()>1.00001*StRed)) {
                        bool mod=OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(StRed,Digits),OrderTakeProfit(),0,Blue);
                        if (mod==true) Print ("#"+OrderTicket()+" sl modified to "+StRed+" (Supertrend)");
                           else Print("Error = ",GetLastError());
                 } 
            }
            
         }
      
      }
      
      for(int i=OrdersTotal() - 1;i>=0; i--) {
         bool os=OrderSelect(i,SELECT_BY_POS);
         
         if ((Bid>OrderOpenPrice()+trailingstart*Point) && OrderSymbol()==Symbol() && OrderMagicNumber()==magic_number  && (OrderStopLoss()+Point<OrderOpenPrice()+4*Point) && ((OrderStopLoss()<0.99999*StGreen) || StGreen!=EMPTY_VALUE)){
            bool res=OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(OrderOpenPrice()+20*Point,Digits),OrderTakeProfit(),0,Blue);
            if(!res) Print("#"+OrderTicket()+" Error in OrderModify. Error code=",GetLastError());
            else Print("#"+OrderTicket()+" order sl moved to 0."); 
         }
         
         if ((Ask<OrderOpenPrice()-trailingstart*Point) && OrderSymbol()==Symbol() && OrderMagicNumber()==magic_number  && (OrderStopLoss()-Point>OrderOpenPrice()-4*Point) && ((OrderStopLoss()>1.00001*StRed) || StRed!=EMPTY_VALUE)){
            bool res=OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(OrderOpenPrice()-20*Point,Digits),OrderTakeProfit(),0,Blue);
            if(!res) Print("#"+OrderTicket()+" Error in OrderModify. Error code=",GetLastError());
            else Print("#"+OrderTicket()+" order sl moved to 0.");
         }
         
      }
   }
   time_bill_m1=iTime(NULL,PERIOD_M1,0);
      
      
   if (par_trail==true){      
                  
         double parSAR = iSAR(NULL,PERIOD_M5,0.02,0.2,1);
                 
         
         for(int i=OrdersTotal() - 1;i>=0; i--) {
            bool os=OrderSelect(i,SELECT_BY_POS);
            
            if (parSAR>OrderOpenPrice() && parSAR!=EMPTY_VALUE){
                 if(OrderSymbol()==Symbol() && OrderMagicNumber()==magic_number  && OrderType()==OP_BUY && (OrderStopLoss()<0.99999*parSAR)) {
                        bool mod=OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(parSAR,Digits),OrderTakeProfit(),0,Blue);
                        if (mod==true) Print ("Order modified: ",OrderTicket());
                           else Print("Error = ",GetLastError());
                 } 
            }
         
               
            if ((OrderOpenPrice()>parSAR) && parSAR!=EMPTY_VALUE){
                 if(OrderSymbol()==Symbol() && OrderMagicNumber()==magic_number  && OrderType()==OP_SELL && (OrderStopLoss()>1.00001*parSAR)) {
                        bool mod=OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(parSAR,Digits),OrderTakeProfit(),0,Blue);
                        if (mod==true) Print ("Order modified: ",OrderTicket());
                           else Print("Error = ",GetLastError());
                 } 
            }  
         }
      
      
      for(int i=OrdersTotal() - 1;i>=0; i--) {
         bool os=OrderSelect(i,SELECT_BY_POS);
         
         if ((Bid>OrderOpenPrice()+trailingstart*Point) && OrderSymbol()==Symbol() && OrderMagicNumber()==magic_number && (OrderStopLoss()+Point<OrderOpenPrice()+4*Point) && ((OrderStopLoss()<0.99999*StGreen) || StGreen!=EMPTY_VALUE)){
            bool res=OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(OrderOpenPrice()+20*Point,Digits),OrderTakeProfit(),0,Blue);
            if(!res) Print("#"+OrderTicket()+" Error in OrderModify. Error code=",GetLastError());
            else Print("#"+OrderTicket()+" order sl moved to 0."); 
         }
         
         if ((Ask<OrderOpenPrice()-trailingstart*Point) && (OrderStopLoss()-Point>OrderOpenPrice()-4*Point) && ((OrderStopLoss()>1.00001*StRed) || StRed!=EMPTY_VALUE)){
            bool res=OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(OrderOpenPrice()-20*Point,Digits),OrderTakeProfit(),0,Blue);
            if(!res) Print("#"+OrderTicket()+" Error in OrderModify. Error code=",GetLastError());
            else Print("#"+OrderTicket()+" order sl moved to 0.");
         }
      
      }
   }
   
      
   ObjectSet("sor_2",OBJPROP_CORNER,3);
   ObjectSet("sor_2",OBJPROP_XDISTANCE,5);
   ObjectSet("sor_2",OBJPROP_YDISTANCE,14);
   ObjectSet("sor_2",OBJPROP_COLOR,Red);
   ObjectSet("sor_2",OBJPROP_WIDTH,3);
   ObjectSet("sor_2",OBJPROP_BACK,false);
   ObjectSet("sor_2",OBJPROP_FONTSIZE,10);
   ObjectSetText("sor_2",StGreen+"|"+StRed+"|"+buy_pending_price[0]+"|"+sell_pending_price[0],10,"Times New Roman");
   
   for(int i=0;i<=4; i++){   
      ObjectDelete("buy_pending"+IntegerToString(i,1));
      ObjectDelete("sell_pending"+IntegerToString(i,1));
   
      if(buy_pending_price[i]>0){
         ObjectCreate("buy_pending"+IntegerToString(i,1),OBJ_HLINE,0,0,buy_pending_price[i]);
         ObjectSet("buy_pending"+IntegerToString(i,1),OBJPROP_COLOR,Green);
         ObjectSet("buy_pending"+IntegerToString(i,1),OBJPROP_STYLE,STYLE_DASH);
      }
      if(sell_pending_price[i]>0){
         ObjectCreate("sell_pending"+IntegerToString(i,1),OBJ_HLINE,0,0,sell_pending_price[i]);
         ObjectSet("sell_pending"+IntegerToString(i,1),OBJPROP_COLOR,Green);
         ObjectSet("sell_pending"+IntegerToString(i,1),OBJPROP_STYLE,STYLE_DASH);
      }
   }
}