import { LightningElement,api,track,wire } from 'lwc';
import getFieldSetupWrapper from '@salesforce/apex/ObjectFieldSetup.getFieldSetUpWrapper';
import upsertFieldSetup from '@salesforce/apex/ObjectFieldSetup.upsertFieldMapping';

import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent } from 'c/pubsub';

export default class FieldMappingComponent extends LightningElement {

    @api connectedSalesforceId;
    @api objectSetupId;
    cloneobjectSetupId ; //private variable to control the function call of getfieldSetupDetails()

    @track toggleSpinner = true;

    @track sourceunmappedLst;
    @track displayresult;
    @track destunmappedLst;

    @wire(CurrentPageReference) pageRef;

    connectedCallback(){
        console.log('Connected callback for fieldmapping component called');
        console.log(this.connectedSalesforceId);
        console.log(this.objectSetupId);
        //this.getfieldSetupDetails();
    }

    renderedCallback(){
        console.log('Rendered callback called for fieldmapping component');
        console.log(this.sourceunmappedLst);
        if(this.cloneobjectSetupId !== this.objectSetupId){
            console.log('inside if');
            this.cloneobjectSetupId = this.objectSetupId;
            this.getfieldSetupDetails();    
        }
        
    }
    
    getfieldSetupDetails(){
        this.toggleSpinner = true;
        getFieldSetupWrapper({salesforceOrgId:this.connectedSalesforceId, objectsetupid:this.objectSetupId})        
        .then(result =>{
            this.toggleSpinner = false;
            console.log('get fieldsetupdetails success ');
            console.log('Mapped list ' + result.mappedLst);
            console.log('sourceunmappedLst ' + result.sourceunmappedLst);
            console.log('sourceunmappedLst ' + result.sourceunmappedLst);
            this.sourceunmappedLst = result.sourceunmappedLst;
            this.displayresult = result.mappedLst;
            this.destunmappedLst = result.destunmappedLst;
        })
        .catch(error =>{
            console.log('get fieldsetupdetails error');
            console.log(error);
        });
    }

    drag(ev) {
        //console.log(ev.currentTarget.getAttribute('data-id'));
        ev.dataTransfer.setData("text", ev.currentTarget.getAttribute('data-id'));
    }

    allowDrop(ev) {
        ev.preventDefault();
    }

    drop(ev) {
        console.log('drop called @@@ ');
        ev.preventDefault();
        let DestinationString = this.destunmappedLst.filter(unit => unit.Destination_Field_Api_Name__c === ev.dataTransfer.getData("text"));
        //console.log(DestinationString.length);
        //console.log(DestinationString[0].Destination_Field_Api_Name__c);
        //console.log(DestinationString[0].Destination_Field_Name__c);
        console.log(this.destunmappedLst.length);
        let DestinationUpdatedList = this.destunmappedLst.filter(unit => unit.Destination_Field_Api_Name__c !== ev.dataTransfer.getData("text"));
        console.log(DestinationUpdatedList.length);
        this.destunmappedLst = DestinationUpdatedList;
        this.sourceunmappedLst.map(function (unit) {
            if (unit != null || unit !== undefined) {
                console.log('unit != null || unit !== undefined @@@@ 1 @@@@@@');
                if (unit.Name != null || unit.Name !== undefined) {
                    console.log(ev.currentTarget.childNodes[0].className + '@@@@ 2 @@@@@@');
                    if (ev.currentTarget.childNodes[0].className !== null) {
                        console.log(ev.currentTarget.childNodes[0].className + '@@@@@ 3 @@@@@@');
                        if (unit.Name === ev.currentTarget.childNodes[0].className) {
                            console.log('unit.Name === ev.currentTarget.childNodes[0].className @@@@@ 4 @@@@@@' );
                            console.log(unit.Destination_Field_Api_Name__c);
                            if(unit.Destination_Field_Api_Name__c === "" || unit.Destination_Field_Api_Name__c === " " || unit.Destination_Field_Api_Name__c === undefined  ){
                               console.log('Sucess');
                               unit.Destination_Field_Api_Name__c =  DestinationString[0].Destination_Field_Api_Name__c;
                               unit.Destination_Field_Name__c = DestinationString[0].Destination_Field_Name__c;
                               console.log(unit.Destination_Field_Api_Name__c);
                               console.log(unit.Destination_Field_Name__c);
                            }
                        }
                    }
                }
            }
        });
    }

    removeFromMapped(event){
        console.log(event.target.name);
        let destination = new Object();
        destination.Destination_Field_Api_Name__c= this.sourceunmappedLst[event.target.name].Destination_Field_Api_Name__c;
        destination.Destination_Field_Name__c = this.sourceunmappedLst[event.target.name].Destination_Field_Name__c;
        destination.Object_setup_name__c= this.sourceunmappedLst[event.target.name].Object_setup_name__c;
        destination.Souce_Field_Api_Name__c = '';
        destination.Name = '';
        console.log(destination);
        this.destunmappedLst.push(destination);
        this.sourceunmappedLst[event.target.name].Destination_Field_Api_Name__c = '';
        this.sourceunmappedLst[event.target.name].Destination_Field_Name__c = '';
        
    }

    upsertFieldMapping(event){
        console.log('Update feild Mapping');
        this.toggleSpinner = true;
        let insertFieldMappingLst = [] ;
        this.displayresult.forEach((item) => {
            insertFieldMappingLst.push(item);
        });
        this.sourceunmappedLst.forEach((item) => {
            insertFieldMappingLst.push(item);
        });
        upsertFieldSetup({fieldSetupLst:insertFieldMappingLst})
        .then(result =>{
            console.log('Success in upsertFieldSetup');
            this.toggleSpinner = false;
        })
        .catch(error =>{
            console.log('error in upsertFieldSetup');
            console.log(error);
        });
        fireEvent(this.pageRef, 'updateSelectObjectPicklist', 'datatemp');
    }
}