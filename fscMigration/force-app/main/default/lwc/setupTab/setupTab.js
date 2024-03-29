/* eslint-disable no-console */
import getObjectSetupWrapper    from '@salesforce/apex/ObjectFieldSetup.getObjectSetupWrapper';
import ObjectSetupInsertion     from '@salesforce/apex/ObjectFieldSetup.objectSetupInsertion';
import {LightningElement, track,api, wire } from 'lwc';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';

export default class SetupTab extends LightningElement {

    @wire(CurrentPageReference) pageRef;

    @api setupconnectedSalesforceOrgId;
    @track displayresult;
    @track sourceunmappedLst;
    @track destunmappedLst;

    @track toggleSpinner;
    @track showObjectSetup;
    @track showObjectFieldSetup;

    @track objectSetupRecordWithIdLst;
    @track objectSelectedForFieldDisplay;
    @track objectSetupSelectedId;

    connectedCallback() {
        // subscribe to searchKeyChange event
        console.log('Connected callback for setup tab called @@@@');
        console.log(this.setupconnectedSalesforceOrgId);
        registerListener('searchKeyChange', this.getCompleteData, this);
        this.getCompleteData(this.setupconnectedSalesforceOrgId);
    }

    disconnectedCallback() {
        // unsubscribe from searchKeyChange event
        unregisterAllListeners(this);
    }

    getCompleteData(setupconnectedSalesforceOrgId) {
        console.log('Event caught @@@@');
        this.toggleSpinner = true;
        getObjectSetupWrapper({ salesforceOrgId: setupconnectedSalesforceOrgId })
            .then(result => {
                if (result) {
                    console.log(result);
                    this.displayresult = result.mappedLst;
                    this.sourceunmappedLst = result.sourceunmappedLst;
                    this.destunmappedLst = result.destunmappedLst;
                    this.toggleSpinner  = false;
                    this.showObjectSetup = true;
                    this.showObjectFieldSetup = false;
                }
            })
            .catch(error => {
                console.log(error);
            })
    }

    allowDrop(ev) {
        ev.preventDefault();
    }

    drag(ev) {
        ev.dataTransfer.setData("text", ev.currentTarget.getAttribute('data-id'));
    }

    drop(ev) {
        console.log('drop called @@@ ');
        ev.preventDefault();
        let DestinationString = this.destunmappedLst.filter(unit => unit.Destination_Object_Api_Name__c === ev.dataTransfer.getData("text"));
        let DestinationUpdatedList = this.destunmappedLst.filter(unit => unit.Destination_Object_Api_Name__c !== ev.dataTransfer.getData("text"));
        this.destunmappedLst = DestinationUpdatedList;
        this.sourceunmappedLst.map(function (unit) {
            if (unit != null || unit !== undefined) {
                if (unit.Name != null || unit.Name !== undefined) {
                    if (ev.currentTarget.childNodes[0].className !== null) {
                        if (unit.Name === ev.currentTarget.childNodes[0].className) {
                            console.log(ev.currentTarget.childNodes[0].className);
                            console.log(unit.Name);
                            console.log(DestinationString);
                            console.log(unit.Destination_Object_Api_Name__c);
                            if(unit.Destination_Object_Api_Name__c !== "" || unit.Destination_Object_Api_Name__c !== " " ){
                                console.log('success');    
                                unit.Destination_Object_Api_Name__c = DestinationString[0].Destination_Object_Api_Name__c;
                                unit.Destination_Object_Name__c     = DestinationString[0].Destination_Object_Name__c;
                            }
                        }
                        
                    }
                }
            }

        });    
        console.log(this.sourceunmappedLst);
    }

    removeFromMapped(event){
        let destination = new Object();
        destination.Destination_Object_Api_Name__c = this.sourceunmappedLst[event.target.name].Destination_Object_Api_Name__c;
        destination.Destination_Object_Name__c = this.sourceunmappedLst[event.target.name].Destination_Object_Name__c;
        destination.SalesforceOrg__c = this.sourceunmappedLst[event.target.name].SalesforceOrg__c;
        destination.Name = '';
        destination.Souce_Object_Api_Name__c = '';
        this.destunmappedLst.push(destination);
        this.sourceunmappedLst[event.target.name].Destination_Object_Api_Name__c = '';
        this.sourceunmappedLst[event.target.name].Destination_Object_Name__c = '';
        
    }

    @api
    nextButtonTriggered(){
        console.log('Child method called');
        console.log(this.displayresult.length);
        console.log(this.sourceunmappedLst.length);
        this.toggleSpinner = true;
        //this.sourceunmappedLst.concat(this.displayresult);
        let insertObjectLst = [] ;
        let self = this;
        this.displayresult.forEach((item) => {
            insertObjectLst.push(item);
            //self.sourceunmappedLst.push(item);
        });
        this.sourceunmappedLst.forEach((item) => {
            insertObjectLst.push(item);
            //self.sourceunmappedLst.push(item);
        });
        console.log(insertObjectLst.length);
        ObjectSetupInsertion({objectSetupLst : insertObjectLst,connectedSalesforceOrgId : this.setupconnectedSalesforceOrgId})
            .then(result => {
                console.log("Success" + result);
                this.toggleSpinner = false;
                this.showObjectSetup =false;
                this.showObjectFieldSetup = true;
                this.objectSetupRecordWithIdLst = result;
                this.objectSelectedForFieldDisplay = 'None';
                this.objectSetupSelectedId = '';
            })
            .catch(error =>{
                console.log("error");
                console.log(error);
            });
        
    }

    @api
    previousButtonTriggered(){
        if(this.showObjectFieldSetup === true && this.showObjectSetup === false){
            this.showObjectFieldSetup = false;
            this.showObjectSetup = true;
        }
    }

    getSelectedObjectFields(event){
        console.log('@@@ getSelectedObjectFields @@@ called');
        console.log(event.target);
        console.log(event.target.firstChild.className);
        //console.log(event.target.firstChild.innerText);
        console.log(this.setupconnectedSalesforceOrgId);
        this.objectSelectedForFieldDisplay = event.target.firstChild.innerText;
        this.objectSetupSelectedId = event.target.firstChild.className;
        //this.objectSelectedForFieldDisplay
    }
}