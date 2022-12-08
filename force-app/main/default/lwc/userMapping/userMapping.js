import { LightningElement, wire, api } from 'lwc';
import getUsers from "@salesforce/apex/UserInfoClass.getUserList";
import { refreshApex } from '@salesforce/apex';
import { updateRecord,getRecordNotifyChange  } from 'lightning/uiRecordApi';
import updateUsers from '@salesforce/apex/UserInfoClass.updateUsers';


import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import NAME_FIELD from '@salesforce/schema/User.Name';
// //import Email_FIELD from '@salesforce/schema/User.Email';
// import Username_FIELD from '@salesforce/schema/User.Username';
// import FilogixId_FIELD from '@salesforce/schema/User.Filogix_Id__c';
// import ID_FIELD from '@salesforce/schema/User.Id';

const COLS = [
    { label: 'Name', fieldName: 'Name', cellAttributes: { iconName: 'standard:avatar' }},
    { label: 'Username', fieldName: 'Username'},
    { label: 'Filogix ID', fieldName: 'CJA_Mortgage__Filogix_Id__c', editable: true  },
];

export default class userMapping extends LightningElement {

    @api recordId;
    columns = COLS;
    draftValues = [];

    @wire(getUsers) users;

    renderedCallback(){
        console.log(JSON.stringify(this.users));
    }
        
    // Using APEX instead of uiRecordApi to have a single DML
    //https://developer.salesforce.com/docs/component-library/documentation/en/lwc/lwc.data_table_inline_edit
    async handleSave(event) {
        const updatedFields = event.detail.draftValues;
        console.log(JSON.stringify(updatedFields));
        
        // Prepare the record IDs for getRecordNotifyChange()
        const notifyChangeIds = updatedFields.map(row => { return { "recordId": row.Id } });
    
        try {
            // Pass edited fields to the updateContacts Apex controller
            const result = await updateUsers({data: updatedFields});
            console.log(JSON.stringify("Apex update result: "+ result));
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Mapping updated',
                    variant: 'success'
                })
            );
    
            // Refresh LDS cache and wires
            getRecordNotifyChange(notifyChangeIds);
    
            // Display fresh data in the datatable
            refreshApex(this.users).then(() => {
                // Clear all draft values in the datatable
                this.draftValues = [];
            });
       } catch(error) {
               this.dispatchEvent(
                   new ShowToastEvent({
                       title: 'Error updating or refreshing records',
                       message: error.body.message,
                       variant: 'error'
                   })
             );
        };
    }
}