/* eslint-disable no-unreachable */
import { LightningElement, api, track } from "lwc";
// import updateFilogix from '@salesforce/apex/ApplicationStatusSync.updateFilogix';
import { getRecordNotifyChange } from "lightning/uiRecordApi";
import sendReportToCJA from "@salesforce/apex/FilogixWrapperBinding.sendReportToCJA";
import updateFilogix from "@salesforce/apex/ApplicationSync.updateApp";

export default class UpdateFromFilogix extends LightningElement {
  @api recordId;
  processedRla;
  returnmsg;
  showbutton = false;
  loaded = false;
  @track iconVisibility = true;
  connectedCallback() {
    //console.log('record id is  ' +this.recordId);
    this.handleupdateFromFilogix();
  }

  sendReport() {
    sendReportToCJA({
      appId: this.recordId,
      ex: this.processedRla,
      action: "get"
    })
      .then(() => {
        this.showbutton = false;
      })
      .catch((err) => {
        console.log(JSON.stringify(err));
      });
  }

  handleupdateFromFilogix() {
    console.log("record id is:  " + this.recordId);
    updateFilogix({ recordID: this.recordId })
      .then((rla) => {
        console.log(JSON.stringify(rla));
        let classname = "slds-text-color_success";
        //   let iconVisibility = true;
        //   this.iconVisibility = true;

        console.log("rla update to Filogix " + rla + " " + typeof rla);
        let msg;

        /*const testerr = {
          status: 500,
          body: {
            fieldErrors: {},
            pageErrors: [
              {
                statusCode: "DUPLICATE_VALUE",
                message:
                  "duplicate value found: LoanApplicantId duplicates value on record with id: 0e22S0000008OQF"
              }
            ],
            index: null,
            duplicateResults: []
          },
          headers: {}
        };

        throw testerr;*/

        if (rla !== "TRUE") {
          //console.log('IF RLA '+ rla);
          classname =
            "slds-text-heading_small slds-align_absolute-center slds-text-color_error";
          this.iconVisibility = false;

          // parse rla
          let parsedRla;
          try {
            parsedRla = JSON.parse(rla);
          } catch (error) {
            parsedRla = "";
            console.log("could not parse rla");
          } finally {
            if (parsedRla) {
              if (parsedRla.body && parsedRla.body.fieldErrors) {
                msg =
                  "<br> <strong>An unexpected error occurred.</strong> <br> " +
                  Object.keys(parsedRla.body.fieldErrors)[0] +
                  ": " +
                  parsedRla.body.fieldErrors[
                    Object.keys(parsedRla.body.fieldErrors)[0]
                  ][0].message +
                  "<br><br>";

                console.log(
                  parsedRla.body.fieldErrors[
                    Object.keys(parsedRla.body.fieldErrors)[0]
                  ][0].message
                );
              } else if (parsedRla.body && parsedRla.body.pageErrors) {
                msg =
                  "<br> <strong>An unexpected error occurred.</strong> <br> " +
                  Object.keys(parsedRla.body.pageErrors)[0] +
                  ": " +
                  parsedRla.body.pageErrors[
                    Object.keys(parsedRla.body.pageErrors)[0]
                  ][0].message +
                  "<br><br>";

                console.log(
                  parsedRla.body.pageErrors[
                    Object.keys(parsedRla.body.pageErrors)[0]
                  ][0].message
                );
              } else {
                msg =
                  "<br> <strong>An unexpected error occurred.</strong> <br> " +
                  parsedRla.result.error.status[0].message +
                  "<br><br>";
              }
            } else {
              if (rla.includes("missing") || rla.toLowerCase().includes("error")) {
                msg = "<br>" + rla;
              } else {
                msg =
                  "<br> <strong>An unexpected error occurred.</strong> <br> " +
                  rla +
                  "<br><br>";
              }
            }
          }
          this.showbutton = true;
          console.log("iconVisibility:: " + this.iconVisibility);
        } else {
          //console.log('ELSE RLA '+ rla);
          classname = "slds-text-heading_small slds-text-color_success";
          //this.iconVisibility = true;
          msg = "<br> Your Request has been initiated. You'll be notified once completed!";
          console.log("iconVisibility:: " + this.iconVisibility);
        }

        //console.log('parsedRla push to Filogix'+ parsedRla);

        this.rlaMessage =
          '<div class="' +
          classname +
          ' " style="display: flex;flex-direction: column;justify-content: center;align-content: center;align-items: center;margin: auto;">' +
          msg +
          "</div>";
        console.log("this.rlaMessage " + this.rlaMessage);
        this.loaded = true;
        this.processedRla = this.rlaMessage;
        // Notify LDS that you've changed the record outside its mechanisms.
        getRecordNotifyChange([{ recordId: this.recordId }]);
        //this.openModal()
      })
      .catch((err) => {
        console.log(JSON.stringify(err));
        console.log("in the catch block");
        let msg = "<br> <strong>An unexpected error occurred.</strong>  <br> ";
        if (
          err.body &&
          err.body.fieldErrors &&
          Object.keys(err.body.fieldErrors).length > 0
        ) {
          console.log(
            err.body.fieldErrors[Object.keys(err.body.fieldErrors)[0]][0]
              .message
          );
          msg += err.body.fieldErrors[Object.keys(err.body.fieldErrors)[0]][0]
            .message
            ? Object.keys(err.body.fieldErrors)[0] +
              ": " +
              err.body.fieldErrors[Object.keys(err.body.fieldErrors)[0]][0]
                .message
            : JSON.stringify(err);
        } else if (
          err.body &&
          err.body.pageErrors &&
          Object.keys(err.body.pageErrors).length > 0
        ) {
          console.log(
            err.body.pageErrors[Object.keys(err.body.pageErrors)[0]][0].message
          );
          msg += err.body.pageErrors[Object.keys(err.body.pageErrors)[0]][0]
            .message
            ? Object.keys(err.body.pageErrors)[0] +
              ": " +
              err.body.pageErrors[Object.keys(err.body.pageErrors)[0]][0]
                .message
            : JSON.stringify(err);
        } else if (err.body && err.body.message) {
          msg += err.body.message;
        }

        let classname = "slds-text-heading_small slds-text-color_error";
        this.rlaMessage =
          '<div class="' +
          classname +
          '" style="display: flex;flex-direction: column;justify-content: center;align-content: center;align-items: center;margin: auto;"> <br> ' +
          msg +
          "<br> Please contact the App Developer. </div><br>";
        this.processedRla = JSON.stringify(err);
        this.iconVisibility = false;
        this.loaded = true;
        this.showbutton = true;
      });

    /*
        .then(result=>{
            let msg;
            let className='slds-text-color_success';
            console.log('result from update Filogix'+JSON.stringify(result));
            if(result!='TRUE'){
                className = 'slds-text-color_error';
                msg = '<b>Something went wrong!</b></br>'+result;
                //this.returnmsg = result;
            } else {
                nmsg = 'Your Request has been processed';
            }

            this.rlaMessage = '<div class="'+className+'">'+msg+'</div>';
            console.log('this.rlaMessage '+this.rlaMessage);
            this.loaded = true;
        })
        .catch(error=>{
            //console.log(error)
            console.log(JSON.stringify(error));
            this.returnmsg = JSON.stringify(error);
            this.loaded = true;
        })
    }*/
  }
}