import { LightningElement, wire, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import LightningConfirm from "lightning/confirm";

import getFilogixUsers from "@salesforce/apex/UserInfoClass.getFilogixUsers";
import saveFilogixUser from "@salesforce/apex/UserInfoClass.saveFilogixUser";
import deleteFilogixUser from "@salesforce/apex/UserInfoClass.deleteFilogixUser";

const STANDARD_USER = "Standard";
// const PARTNER_USER = "PowerPartner";
const MAX_RESULTS = 10;

export default class userMapping extends LightningElement {
  @api recordId; // You can’t remove the following public properties: recordId, because the component is part of a managed package.

  users;
  rows;
  searchStandardUsers;
  searchPartnerUsers;
  error;
  loading = true;

  // modal properties
  showModal = false;
  isEdit = false;
  userId = undefined;

  // modal form properties
  filogixId = undefined;

  userType = undefined;
  userTypeOptions = [
    {
      label: "Standard",
      value: "Standard"
    },
    {
      label: "Partner",
      value: "PowerPartner"
    }
  ];
  isMultiEntry = false;
  initialSelection = [];
  errors = [];

  // delete confirm properties
  userToDelete = undefined;
  showDeleteConfirm = false;

  // get table rows
  @wire(getFilogixUsers)
  getUsers({ data, error }) {
    if (data) {
      console.log(data);
      this.users = data;
      this.rows = this.users.filter((user) => user.FilogixId);
      this.searchStandardUsers = this.users.filter(
        (user) => !user.FilogixId && user.UserType === "Standard"
      );
      this.searchPartnerUsers = this.users.filter(
        (user) => !user.FilogixId && user.UserType === "PowerPartner"
      );
    }

    if (error) {
      this.error = "Unknown error";
      if (Array.isArray(error.body)) {
        this.error = error.body.map((e) => e.message).join(", ");
      } else if (typeof error.body.message === "string") {
        this.error = error.body.message;
      }
      const toastEvent = new ShowToastEvent({
        title: "Error",
        message: this.error,
        variant: "error"
      });
      this.dispatchEvent(toastEvent);
    }

    this.loading = false;
  }

  get modalTitle() {
    return this.isEdit ? "Edit Filogix User" : "New Filogix user";
  }

  get disableLookup() {
    return this.isEdit || !this.userType;
  }

  get disableFilogixIdField() {
    return !this.userType;
  }

  get hasRows() {
    return !this.loading && this.rows && this.rows.length;
  }

  // event handlers

  handleOpenDeleteConfirm(event) {
    this.userToDelete = this.rows.find((r) => r.Id === event.target.value);
    this.showDeleteConfirm = true;
  }

  handleCloseDeleteConfirm() {
    this.showDeleteConfirm = false;
    this.userToDelete = undefined;
  }

  handleDelete() {
    const row = this.userToDelete;

    deleteFilogixUser({ userId: row.Id })
      .then((success) => {
        if (success) {
          this.rows = this.rows.filter((r) => r.Id !== row.Id);

          if (row.UserType === STANDARD_USER) {
            this.searchStandardUsers = [...this.searchStandardUsers, row];
          } else {
            this.searchPartnerUsers = [...this.searchPartnerUsers, row];
          }

          const toastEvent = new ShowToastEvent({
            title: "Success",
            message: "User's Filogix Id removed",
            variant: "success"
          });
          this.dispatchEvent(toastEvent);
        }
      })
      .catch((error) => {
        const toastEvent = new ShowToastEvent({
          title: "Delete Error",
          message: "An error occured trying to delete the filogix field.",
          variant: "error"
        });
        this.dispatchEvent(toastEvent);
        // eslint-disable-next-line no-console
        console.error("Delete error", JSON.stringify(error));
        this.errors = [error];
      })
      .finally(() => {
        this.showDeleteConfirm = false;
        this.userToDelete = undefined;
      });
  }

  handleSave() {
    // check if all feilds are populated
    if (
      !this.userType ||
      !this.template.querySelector("c-lookup").getSelection() ||
      !this.filogixId
    ) {
      const toastEvent = new ShowToastEvent({
        title: "Save Error",
        message: "Please input all fields.",
        variant: "error"
      });
      this.dispatchEvent(toastEvent);
      return;
    }

    const saveUserId =
      this.userId ||
      (this.template.querySelector("c-lookup").getSelection()[0] &&
        this.template.querySelector("c-lookup").getSelection()[0].id);

    // check if valid user is selected
    if (!saveUserId) {
      const toastEvent = new ShowToastEvent({
        title: "Save Error",
        message: "Please enter a valid user.",
        variant: "error"
      });
      this.dispatchEvent(toastEvent);
      return;
    }

    // check if filogix id has correct format
    // if (!/^[0-9a-zA-Z]{3,50}$/.test(this.filogixId)) {
    //   const toastEvent = new ShowToastEvent({
    //     title: "Save Error",
    //     message:
    //       "Please enter a valid Filogix Id (no spaces or special characters).",
    //     variant: "error"
    //   });
    //   this.dispatchEvent(toastEvent);
    //   return;
    // }

    saveFilogixUser({
      userId: saveUserId,
      filogixId: this.filogixId
    })
      .then((success) => {
        if (success && this.isEdit) {
          const tempRows = JSON.parse(JSON.stringify(this.rows));
          tempRows[tempRows.findIndex((r) => r.Id === this.userId)].FilogixId =
            this.filogixId;
          this.rows = tempRows;

          const toastEvent = new ShowToastEvent({
            title: "Success",
            message: "User's Filogix Id updated",
            variant: "success"
          });
          this.dispatchEvent(toastEvent);
        } else if (success) {
          this.rows = [
            {
              Id: saveUserId,
              Name: this.template.querySelector("c-lookup").getSelection()[0]
                .title,
              Email: this.template.querySelector("c-lookup").getSelection()[0]
                .subtitle,
              UserType: this.userType,
              SmallPhotoUrl: this.template
                .querySelector("c-lookup")
                .getSelection()[0].icon,
              FilogixId: this.filogixId
            },
            ...this.rows
          ];
          if (this.userType === STANDARD_USER) {
            this.searchStandardUsers = this.searchStandardUsers.filter(
              (user) => user.Id !== saveUserId
            );
          } else {
            this.searchPartnerUsers = this.searchPartnerUsers.filter(
              (user) => user.Id !== saveUserId
            );
          }

          const toastEvent = new ShowToastEvent({
            title: "Success",
            message: "Added Filogix Id to user.",
            variant: "success"
          });
          this.dispatchEvent(toastEvent);
        }
        this.userId = undefined;
        this.filogixId = undefined;
        this.showModal = false;
        this.isEdit = false;
        this.initialSelection = [];
        this.userType = undefined;
      })
      .catch((error) => {
        const toastEvent = new ShowToastEvent({
          title: "Save Error",
          message: "An error occured trying to save the filogix field.",
          variant: "error"
        });
        this.dispatchEvent(toastEvent);
        // eslint-disable-next-line no-console
        console.error("Save error", JSON.stringify(error));
        this.errors = [error];
      });
  }

  handleOpenEditModal(event) {
    const { Id, Name, Email, UserType, SmallPhotoUrl, FilogixId } =
      this.rows.find((row) => row.Id === event.target.value);

    this.userId = Id;
    this.filogixId = FilogixId;

    if (this.userId) {
      this.userType = UserType;
      this.initialSelection = [
        {
          id: Id,
          sObjectType: "User",
          icon: SmallPhotoUrl,
          title: Name,
          subtitle: Email
        }
      ];
      this.showModal = true;
      this.isEdit = true;
    } else {
      const toastEvent = new ShowToastEvent({
        title: "Error",
        message: "User does not exist",
        variant: "error"
      });
      this.dispatchEvent(toastEvent);
    }
  }

  handleCloseEditModal() {
    this.showModal = false;
    this.isEdit = false;
    this.userId = undefined;
    this.initialSelection = [];
    this.userType = undefined;
    this.filogixId = undefined;
  }

  handleOpenNewModal() {
    this.userId = undefined;
    this.showModal = true;
    this.isEdit = false;
    this.initialSelection = [];
    this.userType = undefined;
    this.filogixId = undefined;
  }

  handleCloseNewModal() {
    this.userId = undefined;
    this.showModal = false;
    this.isEdit = false;
    this.initialSelection = [];
    this.userType = undefined;
    this.filogixId = undefined;
  }

  handleComboBoxChange(event) {
    if (this.userType) {
      this.template.querySelector("c-lookup").handleClearSelectionFromParent();
    }
    this.userType = event.target.value;
  }

  // lookup event handlers
  handleLookupSearch(event) {
    const lookupElement = event.target;
    // Call Apex endpoint to search for records and pass results to the lookup
    this.search({
      searchTerm: event.detail.searchTerm,
      userType: this.userType
    })
      .then((results) => {
        lookupElement.setSearchResults(results);
      })
      .catch((error) => {
        const toastEvent = new ShowToastEvent({
          title: "Lookup Error",
          message: "An error occured while searching with the lookup field.",
          variant: "error"
        });
        this.dispatchEvent(toastEvent);
        // eslint-disable-next-line no-console
        console.error("Lookup error", JSON.stringify(error));
        this.errors = [error];
      });
  }

  handleLookupSelectionChange() {
    // this.checkForErrors();
    // console.log(event.detail[0]);
    // console.log(this.template.querySelector("c-lookup").getSelection()[0].id);
  }

  handleFilogixChange(event) {
    this.filogixId = event.target.value;
  }

  // search as you type
  // @param searchTerm
  // @param UserType
  // @returns Promise<LookupSeachResult[]>
  // LookupSeachResult {
  //  String id;
  //  String sObjectType;
  //  String icon;
  //  String title;
  //  String subtitle;
  // }
  // steps:
  // searchTerm to lowercase
  // name to lowercase and split on " "
  // email to lowercase
  // regex = searchTerm += .*
  // for user in search set regex test against name array and email
  // if match found add to result set
  search({ searchTerm, userType }) {
    return new Promise((resolve) => {
      searchTerm = searchTerm.toLowerCase() + ".*";
      const regex = new RegExp(searchTerm);
      const searchOptions =
        userType === STANDARD_USER
          ? this.searchStandardUsers
          : this.searchPartnerUsers;
      let LookupSeachResult = [];
      let nameArray;
      let toInclude;

      for (const user of searchOptions) {
        toInclude = false;
        if (LookupSeachResult.length === MAX_RESULTS) break;

        toInclude = regex.test(user.Email.toLowerCase());
        if (toInclude) {
          LookupSeachResult.push({
            id: user.Id,
            sObjectType: "User",
            icon: user.SmallPhotoUrl,
            title: user.Name,
            subtitle: user.Email
          });
          continue;
        }

        nameArray = user.Name.toLowerCase().split(" ");
        for (const name of nameArray) {
          toInclude = regex.test(name);
          if (toInclude) break;
        }

        if (toInclude) {
          LookupSeachResult.push({
            id: user.Id,
            sObjectType: "User",
            icon: user.SmallPhotoUrl,
            title: user.Name,
            subtitle: user.Email
          });
        }
      }

      resolve(LookupSeachResult);
    });
  }
}