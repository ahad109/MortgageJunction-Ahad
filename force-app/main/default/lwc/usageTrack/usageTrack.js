import { LightningElement } from 'lwc';
import getMonthlyReport from '@salesforce/apex/CalloutHandler.getMonthlyReport';
//import {FlowAttributeChangeEvent,FlowNavigationNextEvent} from "lightning/flowSupport";
export default class usageTrack extends LightningElement {
    
    currentPlan = 'Basic'
    usageLastMonth = 0;
    usageMTD= 0;
    loaded =false;    
    errorDisplayed;
    
    connectedCallback(){
        console.log('connected callback');
        let month = new Date().getMonth()+1; // Adding +1 as getMonth starts from 0 for January.
        let year = new Date().getFullYear();
        let arrayOfMonths = [];
        let prevYear = year;
        let res=[];


        let prevMont;
         // If month is January, then we need to get the last year's December month.
        if(Number(month) === 1 ){
            prevMont = 12
            prevYear = Number(year) -1
        } else {
            prevMont = month-1;
        }
        let currentMonth=month+'_'+year;
        let prevMonth=prevMont+'_'+prevYear;
        // arrayOfMonths.push(month+'_'+year);
        // arrayOfMonths.push(prevMont+'_'+prevYear);
        arrayOfMonths.push(currentMonth);
        arrayOfMonths.push(prevMonth);
        
        //let url = 'https://monthly-report-tracking.herokuapp.com/getMonthlyReport?month='+  month+'_'+year  +','  +prevMont+'_'+prevYear      
        
        // Passing the data to Apex for the Callout
        getMonthlyReport({ListOfMonths: arrayOfMonths})
        .then( result =>{
            console.log(result+' type of ' +typeof(result));

            let tempResult = JSON.parse(result)
            console.log(JSON.stringify(tempResult)+' type of ' +typeof(tempResult));
            
            if(tempResult.monthlyReport){
                let monthlyReport = tempResult.monthlyReport;
                if(monthlyReport.length > 0){
                    // tempResult.map(item=>res[item.month]=item.count)
                    // res[prevMonth]&&(this.usageLastMonth=res[prevMonth])
                    // res[currentMonth]&&(this.usageMTD=res[currentMonth]);
                    let previousMonthCount=monthlyReport.filter(obj=>obj.month===prevMonth).reduce((previousValue,currentValue)=>previousValue+currentValue.count,0)
                    let currentMonthCount=monthlyReport.filter(obj=>obj.month===currentMonth).reduce((previousValue,currentValue)=>previousValue+currentValue.count,0)
                    // this.usageLastMonth=previousMonthCount&&(this.usageLastMonth=previousMonthCount);
                    // this.usageMTD=currentMonthCount&&currentMonthCount;

                    this.usageLastMonth= typeof(this.usageLastMonth) != 'undefined' ? previousMonthCount : 0;
                    this.usageMTD = typeof(this.usageMTD) != 'undefined' ? currentMonthCount : 0;
                }
            } else {
                tempResult = tempResult.result;
            }
            
            this.loaded = true;
        })
        .catch(err => {
            console.log('Error ' +JSON.stringify(err));
            if(err.body.message){
                this.errorDisplayed=err.body.message;
            } else {
                this.errorDisplayed='Something went wrong. Please try again later';
            }
            this.loaded = true;
        })
    }
      
    

    
}