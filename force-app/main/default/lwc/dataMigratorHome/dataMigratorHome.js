/* eslint-disable no-console */
/* eslint-disable @lwc/lwc/no-inner-html */
import { LightningElement,track, wire } from 'lwc';
import getSalesforceOrgLst from '@salesforce/apex/DataMigratorHome.getConnetecSaleforceOrg';
import validateConnection from '@salesforce/apex/DataMigratorHome.validateConnection';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent } from 'c/pubsub';  

export default class DataMigratorHome extends LightningElement {
    
    @wire(CurrentPageReference) pageRef;

    @wire(getSalesforceOrgLst)
    salesforceOrgLst;

    @track objectName;
    @track FieldsName;
    @track openmodal = false;
    @track orgName;
    @track userName;
    @track password;
    @track clientSecret;
    @track clientId;
    @track typeOfOrgIsSandBox = false;

    @track connectedSalesforceOrgId;
    @track connectedSalesforceOrgName;

    @track mappingObjLst = [];
    @track value = 'inProgress';
    @track options;

    newConnection(){
        this.openmodal = true;
        console.log('Open modal called');
    }

    handleOrgNameChange(event){
        this.orgName = event.target.value;
    }

    handleUserNameChange(event){
        this.userName = event.target.value;
    }

    handlePasswordChange(event){
        this.password = event.target.value;
    }
    
    handleClientSecretChange(event){
        this.clientSecret = event.target.value;
    }

    handleClientIdChange(event){
        this.clientId = event.target.value;
    }

    handleTypeOfOrgIsSandBox(event){
        this.typeOfOrgIsSandBox = event.target.checked;
    }

    saveDetails(){
        validateConnection({orgName:this.orgName,
            userName:this.userName,
            pwd:this.password,
            clientid:this.clientId,
            clientsecret:this.clientSecret,
            typeOfOrgIsSandbox:this.typeOfOrgIsSandBox})
            .then(result => {
            if(result.includes('Success')){
                const evt = new ShowToastEvent({
                    title: 'Connection Succesfull',
                    message: 'Your Connected Salesforce Org is successfully authenticated',
                    variant: 'success',
                });
                this.dispatchEvent(evt);
                refreshApex(this.salesforceOrgLst);
                this.openmodal = false;
            }//end of if
            else{
                const evt = new ShowToastEvent({
                    title: 'Connection Failed',
                    message: 'Could not authenticate the connected org. Please recheck your credentials',
                    variant: 'error',
                });
                this.dispatchEvent(evt);
            } 
            })
            .catch(error => {
            console.log('Validation catch'+error);
            });

    }
    closeModal(){
        this.openmodal = false;
    }

    openSelectedOrg(event){
        this.connectedSalesforceOrgId = event.target.parentNode.className;
        this.connectedSalesforceOrgName = event.target.innerHTML;
        console.log('Fire event');
        fireEvent(this.pageRef, 'searchKeyChange', this.connectedSalesforceOrgId);
    }

    handleChange(event) {
        this.value = event.detail.value;
    }

    nextButtonClick(){
        this.template.querySelector('c-setup-tab').nextButtonTriggered();
    }

}