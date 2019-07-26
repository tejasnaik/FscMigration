import { LightningElement,api,track,wire } from 'lwc';
import getObjectSetupOptions from '@salesforce/apex/ExportDataController.getObjectSetupOptions';
import exportData from '@salesforce/apex/ExportDataController.exportData';

import { CurrentPageReference } from 'lightning/navigation';
import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsub';


export default class ExportData extends LightningElement {

    @wire(CurrentPageReference) pageRef;
    @api exportDataConnectedSalesforceOrgId;
    copyexportDataConnectedSalesforceOrgId;

    @track objSelected ;
    @track objectSetupOptLst = [];
    @track objectSetupLst;

    @track toggleSpinner = false

    //Variables to be used to display in slds box
    @track connectedSalesforceOrgName;
    @track mappedObjName;
    @track selectedObjName;

    //variable used to send data to batch
    @track batchObject;

    // connectedCallback(){
    //     // subscribe to searchKeyChange event
    //     registerListener('updateSelectObjectPicklist', this.eventcaught, this);
    // }
    renderedCallback(){
        console.log('rendered callback export data  called');
        if(this.exportDataConnectedSalesforceOrgId !== this.copyexportDataConnectedSalesforceOrgId){
            this.copyexportDataConnectedSalesforceOrgId = this.exportDataConnectedSalesforceOrgId;
            this.connectedSalesforceOrgName =  '';
            this.mappedObjName = '';
            this.selectedObjName = '';
            this.objSelected = '';
            this.objectSetupOptLst = [];
            this.objectSetupLst = [];
            this.toggleSpinner = true;
            this.objsetupoptions();
        }
        
    }    
    objsetupoptions() {

        getObjectSetupOptions({connectedSalesforceOrgId:this.exportDataConnectedSalesforceOrgId})
        .then(result =>{
            console.log('Success in get options list');
            console.log(result);
            this.objectSetupLst = result;
            let self = this;
            result.forEach(function(item){
                self.objectSetupOptLst = [...self.objectSetupOptLst ,{value: item.Destination_Object_Name__c , label: item.Name}];
            });
              console.log(this.objectSetupOptLst);
              this.toggleSpinner = false;
        })
        .catch(error =>{
            this.toggleSpinner = false;
            console.log('error in get options list');
            console.log(error);
        })
        //return this.objectSetupOptLst;
        
    }

    get objoptions(){
        return this.objectSetupOptLst;
    }
    handleObjectChange(event) {
        console.log('Obeject selected @@@');
        this.objSelected = event.detail.value;
        console.log(this.objSelected);
        let self = this;
        let selectedObj = this.objectSetupLst.filter(function(item){
            return item.Destination_Object_Name__c === self.objSelected;
        });

        this.batchObject = selectedObj[0];
        this.mappedObjName = selectedObj[0].Destination_Object_Name__c;
        this.connectedSalesforceOrgName = selectedObj[0].SalesforceOrg__r.Name;
        this.selectedObjName = selectedObj[0].Name;

        console.log(selectedObj[0]);
        console.log('selectedObj.Destination_Object_Name__c @@@@ '+ selectedObj[0].Destination_Object_Name__c);
        console.log('connectedSalesforceOrgName  @@@@ ' + selectedObj[0].SalesforceOrg__r.Name);
    }

    startExport(){
        //this.toggleSpinner = true;
        console.log('start data called');
        console.log(this.batchObject);
        console.log('Object setup id @@@ ' + this.batchObject.Id);
        console.log('Sales force org @@@ ' + this.batchObject.SalesforceOrg__r.Id);
        exportData({objectSetupRecordId:this.batchObject.Id , salesforceOrgId:this.batchObject.SalesforceOrg__r.Id})
        .then(result =>{
            //this.toggleSpinner = false;
            console.log('success export data ');
            console.log('Batch id @@@ ' + result);
            let jsobj ={tabname:'Transaction',jobid:result};
            fireEvent(this.pageRef, 'activateTransactionTab',jsobj);
        })
        .catch(error =>{
            this.toggleSpinner = false;
            console.log('Error in export data ');
            console.log(error);
        })

    }

    // eventcaught(transferdata){
    //     console.log('Event caught in export data ');
    //     console.log(transferdata);
    // }
}