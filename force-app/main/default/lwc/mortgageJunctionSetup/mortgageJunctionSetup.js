import { LightningElement } from "lwc";
import getUserInfo from "@salesforce/apex/UserInfoClass.getUserInfo";
import updateUserInfo from "@salesforce/apex/UserInfoClass.updateUserInfo";
import getConfig from "@salesforce/apex/UpdateCMD.getConfig";
import getAuth from "@salesforce/apex/UpdateCMD.getAuth";
import apexSearch from "@salesforce/apex/UserInfoClass.search";
import updateConfig from "@salesforce/apex/UpdateCMD.updateConfig";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { FlowNavigationNextEvent } from "lightning/flowSupport";

export default class MortgageJunctionSetup extends LightningElement {
  //Variables
  //saves the ID option
  OptionSelected; //Either 'ORGID' or 'USERID'
  Selection = {
    Id: "",
    icon: "",
    title: "",
    name: "",
    subtitle: ""
  };
  SelectionCheck = true;
  //Dynamic class for table
  tableResponsive = "overflow-auto";
  errors_lookup = [{ id: "Error", message: "Please Fill this Field" }];
  //Will Store User Records
  allUsers = [];
  records = [];
  recordMap = new Map();
  queryTerm;
  SelectedUser;
  users = [];
  disabled = false;
  config = {
    CJA_Mortgage__OrgId__c: "0",
    CJA_Mortgage__FirmCode__c: "",
    Is_Live__c: false,
    Label: "Mortgage Junction Config",
    DeveloperName: "Mortgage_Junction_Config",
    QualifiedApiName: "Mortgage_Junction_Config",
    sobjectType: "MortgageJunction_Config__mdt"
  };

  auth = {
    CJA_Mortgage__Username__c: "",
    CJA_Mortgage__Password__c: "",
    CJA_Mortgage__Access_Token__c: null,
    CJA_Mortgage__Token_Expiry__c: null,
    Label: "MJ Auth",
    DeveloperName: "MJ_Auth",
    QualifiedApiName: "MJ_Auth",
    sobjectType: "MJAuth__mdt"
  };

  loaded = false;

  //Getters
  //Options for Selecting id
  // get options(){
  //     return [
  //         {label:'Org Id', value:'ORGID'},
  //         {label:'User Id', value:'USERID'},
  //     ]
  // }
  // //In case the user changes or selects the ID options
  // handleComboboxChange(e){
  //     this.OptionSelected = e.target.value
  //     console.log('this.OptionSelected ' + this.OptionSelected)
  // }
  //  //get boolean show textbox for ORG ID
  // get showOrgIdField(){
  //     if(this.OptionSelected == 'ORGID'){
  //         return true
  //     }
  //     return false
  // }
  //Columns to Show incase user is selected
  get Columns() {
    return [
      { label: "User ", value: "User" },
      { label: "Filogix Id", value: "FilogixId" },
      { label: "Action", value: "Action" }
    ];
  }

  // //get boolean show table for users
  // get showDataTable(){
  //     if(this.OptionSelected == 'USERID'){
  //         if(this.records.length == 0){
  //             this.addUser()
  //             this.getuserRecords()
  //         }
  //         return true
  //     }
  //     return false
  // }

  handleSearch(event) {
    const lookupElement = event.target;
    console.log("Handle Search :: " + JSON.stringify(lookupElement));

    let selectedIds = [];
    for (let temp of this.records) {
      selectedIds.push(temp.Id);
      console.log("Push ID to selectedIds :: " + JSON.stringify(selectedIds));
    }
    apexSearch({
      searchTerm: event.detail.searchTerm,
      selectedIds
    })
      .then((results) => {
        console.log("Results from Search " + JSON.stringify(results));
        lookupElement.setSearchResults(results);
      })
      .catch((error) => {
        // TODO: handle error
        console.log("Error in Search " + JSON.stringify(error));
      });
  }
  initLookupDefaultResults() {
    // Make sure that the lookup is present and if so, set its default results
    const lookup = this.template.querySelector("c-lookup");
    if (lookup) {
      lookup.setDefaultResults({});
    }
  }
  handleSelectionChange(event) {
    try {
      //const selectedIds = event.detail;
      const selectedIds = event.target;
      console.log("selectedIds== >> " + JSON.stringify(selectedIds));
      console.log(
        "getSelection selectedIds== >> " +
          JSON.stringify(event.target.getSelection().Id)
      );
      let Selection = event.target.getSelection();
      console.log("selections==> " + JSON.stringify(Selection));
      let dataId = Number(event.target.dataset.id);
      console.log(
        "event.target.dataset.id:: " + JSON.stringify(event.target.dataset.id)
      );
      console.log(
        "Number(event.target.dataset.id):: " +
          JSON.stringify(Number(event.target.dataset.id))
      );
      console.log("dataId " + dataId);

      let temp = this.recordMap.get(dataId);
      console.log(temp);
      let tempFilogixId = temp.CJA_Mortgage__Filogix_Id__c;
      temp.CJA_Mortgage__Filogix_Id__c = "";

      if (temp) {
        if (temp.CJA_Mortgage__Filogix_Id__c == "") {
          // updateUserInfo({ usrList: [this.records[dataId]] }).then((result) => {
          //   console.log(JSON.stringify(result));
          // });
        }
        temp.CJA_Mortgage__Filogix_Id__c = tempFilogixId;
        let myArr = Selection[0].subtitle.split("-");

        (temp.Name = Selection[0].name),
          (temp.Id = Selection[0].Id),
          (temp.Email = myArr[0]),
          (temp.Profile = myArr[1]),
          (temp.showValue = true);

        console.log("Temp is now ==> " + JSON.stringify(temp));
        this.recordMap.set(dataId, temp);
        this.records = Array.from(this.recordMap.values());
        console.log("Temp is now ==> " + JSON.stringify(this.records));
      }
    } catch (error) {}
  }
  /**
   *
   * @param {Old Search} e
   */
  // handleKeyUp(evt) {
  //   this.queryTerm = evt.target.value;
  //   console.log(this.queryTerm);
  //   for (let i = 0; i < this.allUsers.length; i++) {
  //     if (
  //       this.allUsers[i].label
  //         .toUpperCase()
  //         .includes(this.queryTerm.toUpperCase()) &&
  //       !this.users.includes(this.allUsers[i].label)
  //     ) {
  //       this.allUsers[i].showValue = true;
  //       console.log(" this.allUsers[i].label  " + this.allUsers[i].label);
  //     } else {
  //       this.allUsers[i].showValue = false;
  //     }
  //   }
  // }

  toggleUserComboCancel(e) {
    let rowNumber = Number(e.target.dataset.id);
    this.disabled = !this.disabled; //we will disable edit button so that other rows can not be edited.
    this.SelectionCheck = true;
    let temp = this.recordMap.get(rowNumber);
    temp.showUserCombo = !temp.showUserCombo;
    if (temp.Name == "" && temp.CJA_Mortgage__Filogix_Id__c == "") {
      this.recordMap.delete(rowNumber);
      this.records = Array.from(this.recordMap.values());
    }
  }
  toggleUserComboCheck(e) {
    let rowNumber = Number(e.target.dataset.id);
    this.disabled = !this.disabled; //we will disable edit button so that other rows can not be edited.
    // this.SelectionCheck = !this.SelectionCheck;
    console.log(
      "Toggling Check from " +
        this.records[rowNumber].showUserCombo +
        " to " +
        !this.records[rowNumber].showUserCombo +
        " Disabled " +
        this.disabled
    );
    let temp = this.recordMap.get(rowNumber);
    if (temp.Name != "" && temp.CJA_Mortgage__Filogix_Id__c != "") {
      this.Selection = {
        Id: temp.Id,
        icon: "standard:user",
        title: temp.Name,
        name: temp.Name,
        subtitle: temp.Name
      };
      temp.showUserCombo = !temp.showUserCombo;
      if (this.reportValidityOfInput()) {
        this.recordMap.set(rowNumber, temp);
        this.records = Array.from(this.recordMap.values());
        this.checkIfFiledsSaved(rowNumber);
      } else {
        temp.showUserCombo = !temp.showUserCombo;
      }
    } else {
      //if cancel after adding a new user.
      if (temp.Name == "" && temp.CJA_Mortgage__Filogix_Id__c == "") {
        this.recordMap.delete(rowNumber);
        this.records = Array.from(this.recordMap.values());
      }
    }
  }
  connectedCallback() {
    //this.getuserRecords(); - Don't need anymore
    getConfig().then((result) => {
      if (result) {
        console.log("Result from MeaData = " + JSON.stringify(result));
        if (result.length === 0) {
          console.log("Setting default values");
          this.config = {
            CJA_Mortgage__OrgId__c: "",
            CJA_Mortgage__FirmCode__c: "",
            CJA_Mortgage__Is_Live__c: false,
            Label: "Mortgage Junction Config",
            DeveloperName: "Mortgage_Junction_Config",
            QualifiedApiName: "Mortgage_Junction_Config",
            sobjectType: "CJA_Mortgage__MortgageJunction_Config__mdt"
          };
        } else {
          this.config = result[0];
        }
      }
      console.log("Config = " + JSON.stringify(this.config));
      // this.loaded = true;
    });
    getAuth().then((result) => {
      if (result) {
        console.log("Result from MeaData = " + JSON.stringify(result));
        if (result.length === 0) {
          console.log("Setting default values");
          this.auth = {
            CJA_Mortgage__Username__c: "",
            CJA_Mortgage__Password__c: "",
            CJA_Mortgage__Access_Token__c: null,
            CJA_Mortgage__Token_Expiry__c: null,
            Label: "MJ Auth",
            DeveloperName: "MJ_Auth",
            QualifiedApiName: "MJ_Auth",
            sobjectType: "CJA_Mortgage__MJAuth__mdt"
          };
        } else {
          this.auth = result[0];
          this.auth.CJA_Mortgage__Access_Token__c = null;
          this.auth.CJA_Mortgage__Token_Expiry__c = null;
        }
      }
      console.log("Auth = " + JSON.stringify(this.auth));
      this.loaded = true;
    });
  }

  getuserRecords() {
    console.log("CHANGES REFLECTED");
    getUserInfo()
      .then((userInfo) => {
        console.log(JSON.stringify(userInfo));
        let tempArray = [];
        for (let i = 0; i < userInfo.length; i++) {
          tempArray.push({
            label: userInfo[i].Name,
            value: i,
            CJA_Mortgage__Filogix_Id__c:
              userInfo[i].CJA_Mortgage__Filogix_Id__c,
            id: userInfo[i].Id,
            showValue: false
          });

          if (tempArray[i].CJA_Mortgage__Filogix_Id__c) {
            this.users.push(userInfo[i].Name);
            this.recordMap.set(this.recordMap.size, {
              RowIndex: this.recordMap.size,
              Name: userInfo[i].Name,
              Email: userInfo[i].Email,
              Profile: userInfo[i].Profile.Name,
              Id: userInfo[i].Id,
              CJA_Mortgage__Filogix_Id__c:
                userInfo[i].CJA_Mortgage__Filogix_Id__c,
              showValue: false,
              showUserCombo: false
            });
          }
        }

        this.allUsers = tempArray;
        this.records = Array.from(this.recordMap.values());

        console.log(
          "records displayed Initially = > " + JSON.stringify(this.records)
        );
        console.log("All users => " + JSON.stringify(this.allUsers));
      })
      .catch((error) => console.log(JSON.stringify(error)));
  }

  addUser() {
    this.SelectionCheck = false;
    this.disabled = true; //disable the edit buttons
    this.recordMap.set(this.records.length, {
      RowIndex: this.records.length,
      Name: "",
      Id: "",
      Email: "",
      Profile: "",
      CJA_Mortgage__Filogix_Id__c: "",
      showUserCombo: true
    });

    this.records = Array.from(this.recordMap.values());

    console.log("Record list is now ==> " + JSON.stringify(this.records));
  }

  removeUser(e) {
    let rowNumber = e.target.dataset.id;
    console.log(
      "Remove user @ " +
        rowNumber +
        " " +
        this.recordMap.get(rowNumber).CJA_Mortgage__Filogix_Id__c
    );
    if (
      this.recordMap.has(rowNumber) &&
      this.recordMap.get(rowNumber).CJA_Mortgage__Filogix_Id__c != ""
    ) {
      this.records[rowNumber].CJA_Mortgage__Filogix_Id__c = "";
      updateUserInfo({ usrList: this.records })
        .then((result) => {
          console.log(result);
          if (this.recordMap.has(rowNumber)) {
            this.recordMap.delete(rowNumber);
            this.records = Array.from(this.recordMap.values());
          }
        })
        .catch((error) => console.log(JSON.stringify(error)));
    }
  }

  reportValidityOfInput() {
    console.log("reportValidityOfInput running");
    var temp = true;
    var inputs = this.template.querySelectorAll(".checkvalidation");
    inputs.forEach((input) => {
      if (!input.checkValidity()) {
        input.reportValidity();
        temp = false;
      }
    });

    console.log("return of reportValidityOfInput : " + temp);
    return temp;
  }

  checkIfFiledsSaved(rowNumber) {
    let Name = this.records[rowNumber].Name;
    let Id = this.records[rowNumber].Id;
    let CJA_Mortgage__Filogix_Id__c =
      this.records[rowNumber].CJA_Mortgage__Filogix_Id__c;
    console.log(Name, Id, CJA_Mortgage__Filogix_Id__c);
    if (Name && Id && CJA_Mortgage__Filogix_Id__c) {
      updateUserInfo({ usrList: [this.records[rowNumber]] }).then((result) => {
        console.log(JSON.stringify(result));
      });

      return true;
    } else {
      return false;
    }
  }

  handleFirmCodeChange(e) {
    this.config.CJA_Mortgage__FirmCode__c = e.target.value;
  }

  handleFilogixIdChange(e) {
    this.config.CJA_Mortgage__OrgId__c = e.target.value;
  }

  handleUsernameChange(e) {
    this.auth.CJA_Mortgage__Username__c = e.target.value;
  }

  handlePasswordChange(e) {
    this.auth.CJA_Mortgage__Password__c = e.target.value;
  }

  handleIsLiveChange(e) {
    this.config.CJA_Mortgage__Is_Live__c = e.target.checked;
  }

  handleUserChange(e) {
    let rowNumber = e.target.dataset.id;
    console.log("User Changed @" + rowNumber);
    let temp = this.recordMap.get(Number(rowNumber));
    console.log("User was == > " + JSON.stringify(temp));
    console.log("Get name " + e.target.dataset.item);
    temp.Name = this.allUsers[e.target.dataset.item].label;
    temp.Id = this.allUsers[e.target.dataset.item].id;
    if (!this.users.includes(temp.Name)) {
      this.users.push(temp.Name);
    }
    this.allUsers[e.target.dataset.item].showValue = false;
    // temp.showUserCombo = false
    this.recordMap.set(Number(rowNumber), temp);
    this.records = Array.from(this.recordMap.values());
    console.log(
      " this.records after User Chang  " + JSON.stringify(this.records)
    );
  }
  handleChangeinFilogixId(e) {
    let rowNumber = Number(e.target.dataset.id);
    console.log(" rowNumber is " + rowNumber);
    let temp = this.recordMap.get(Number(rowNumber));
    temp.CJA_Mortgage__Filogix_Id__c = e.target.value;
    // temp.showUserCombo = false
    this.recordMap.set(Number(rowNumber), temp);
    this.records = Array.from(this.recordMap.values());
    console.log(
      " this.records after User FilogixId Change  " +
        JSON.stringify(this.records)
    );
  }

  // handleUserSave(e){

  //     updateUserInfo({usrList: this.records })
  //     .then(result=>{
  //         console.log(JSON.stringify(result))
  //     })
  // }

  handleUserDelete(e) {
    if (confirm("Are you sure?") == true) {
      let rowNumber = Number(e.target.dataset.id);
      console.log("handleUserDelete running ", rowNumber);

      if (this.recordMap.has(rowNumber)) {
        console.log("map has  ", rowNumber);
        let temp = this.recordMap.get(rowNumber);
        console.log("TEMP IS " + JSON.stringify(temp));
        temp.CJA_Mortgage__Filogix_Id__c = "";
        this.recordMap.set(rowNumber, temp);
        console.log(this.recordMap.get(rowNumber));
        if (temp.CJA_Mortgage__Filogix_Id__c == "") {
          console.log("Update call in delete");
          updateUserInfo({ usrList: this.records })
            .then((result) => {
              console.log(result);
            })
            .catch((error) => {
              console.log(error);
            });
        }

        this.recordMap.delete(rowNumber);
        this.records = Array.from(this.recordMap.values());
      } else {
        console.log("Doesnt exist");
      }
    }
  }

  handleDataSave(e) {
    const isInputsCorrect = [
      ...this.template.querySelectorAll(".checkValid")
    ].reduce((validSoFar, inputField) => {
      inputField.reportValidity();
      return validSoFar && inputField.checkValidity();
    }, true);

    if (isInputsCorrect) {
      this.config.sobjectType = "CJA_Mortgage__MortgageJunction_Config__mdt";
      this.auth.sobjectType = "CJA_Mortgage__MJAuth__mdt";

      let requests = [{ data: [this.config, this.auth] }];
      console.log("Config to save  " + JSON.stringify(requests));
      updateConfig({ requests })
        .then((result) => {
          const event = new ShowToastEvent({
            title: "Success",
            message: "Settings Updated Successfully!",
            variant: "success"
          });
          this.dispatchEvent(event);
        })
        .catch((error) => {
          console.log(JSON.stringify(error));

          const event = new ShowToastEvent({
            title: "Error",
            message: "Error while saving config.",
            variant: "error"
          });
          this.dispatchEvent(event);
        });
    }
  }

  handleNext(e) {
    //Go to Next screen of Flow

    const nextNavigationEvent = new FlowNavigationNextEvent();
    this.dispatchEvent(nextNavigationEvent);
  }
}