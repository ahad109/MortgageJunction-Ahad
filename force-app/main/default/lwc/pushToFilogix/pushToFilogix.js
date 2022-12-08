import { LightningElement,api, track } from 'lwc';
import getResidentialLoanApplication from '@salesforce/apex/ApplicationSync.createApp';
import sendReportToCJA from '@salesforce/apex/FilogixWrapperBinding.sendReportToCJA';
import { getRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';
import { FlowNavigationFinishEvent  } from 'lightning/flowSupport';

export default class PushToFilogix extends LightningElement {

    @api recordId;
    processedRla;
    rlaMessage='';
    showbutton=false;
    loaded = false;
    showLoader = false;
    prompt=true;
    @track iconVisibility = true;
    connectedCallback(){
        console.log('This recordId ' +this.recordId);
        //this.handlePushToFilogix();
    }

    sendReport(event){
        sendReportToCJA({appId:this.recordId, ex: this.processedRla, action:'post'})
        .then(success =>{
            this.showbutton=false;
            this.iconVisibility = false;
        })
        .catch(err=>{
            console.log(JSON.stringify(err));
        });
    }    

    closeQuickAction() {
        const navigateNextEvent = new FlowNavigationFinishEvent();
        this.dispatchEvent(navigateNextEvent);
    }


    handlePushToFilogix(){
        this.showLoader=true;
        let msg;
        console.log('this.showLoader1 '+this.showLoader);
        getResidentialLoanApplication({recId:this.recordId})
        .then(rla =>{
            console.log('this.showLoader2 '+this.showLoader);
            let classname='slds-text-heading_small slds-align_absolute-center slds-text-color_success';
            console.log('rla push to Filogix'+ rla + ' ' +typeof(rla));
            msg = '<br>'+ rla;
            
            if(rla.toLowerCase().includes('error') || rla.includes('missing') || rla.includes('exists') ||rla.includes('Trace') || rla.includes('mapping')){
                let parsedRla;
                try {
                    parsedRla = JSON.parse(rla);
                } catch (error) {
                    parsedRla ='';
                }
                finally{
                    classname = 'slds-text-color_error';
                    this.iconVisibility = false;
                    if(parsedRla){
                        if(Object.keys(parsedRla).includes('body')){
                            msg = '<br>An unexpected error occurred. <br> '+parsedRla.body.message + '<br><br>';
                        } else {
                            msg = '<br>An unexpected error occurred. <br> '+parsedRla.result.error.status[0].message + '<br><br>';
                        }
                    }
                    else{
                        if(rla.includes('missing')){
                            msg = '<br>' + rla;
                        } else {
                            msg = '<br>An unexpected error occurred. <br> '+rla + '<br><br>';
                        }
                        
                    }
                    
                }
                console.log('parsedRla push to Filogix'+ parsedRla);
                console.log('this.showLoader3 '+this.showLoader);
                
            }
            this.processedRla = msg;
            if(msg.includes("went wrong!")){
                this.showbutton=true;
                this.iconVisibility = false;
            }
            console.log('this.showLoader4 '+this.showLoader);
            console.log('iconVisibility '+this.iconVisibility);
            this.rlaMessage = '<div class="slds-align_absolute-center"><div class="'+classname+'">'+msg+'</div></div>';
            console.log('this.rlaMessage '+this.rlaMessage);
            this.loaded = true;
            this.prompt=false;
        this.showLoader=false;
        
            // Notify LDS that you've changed the record outside its mechanisms.
            getRecordNotifyChange([{recordId: this.recordId}]);
            //this.openModal()
        })
        .catch(err=>{
            console.log(JSON.stringify(err));
            let classname = 'slds-text-heading_small slds-align_absolute-center slds-text-color_error';
            this.rlaMessage = '<div class="'+classname+'">'+JSON.stringify(err)+'</br> Please contact the App Developer.</div> <br>';
            this.loaded = true;
            this.showbutton=true;
            this.iconVisibility = false;
            this.prompt=false;
        this.showLoader=false;

        });
        
        console.log('this.showLoader5'+this.showLoader);
    }
}