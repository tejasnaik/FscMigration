import { LightningElement,api,track } from 'lwc';
import getFieldSetupWrapper from '@salesforce/apex/ObjectFieldSetup.getFieldSetUpWrapper';

export default class FieldMappingComponent extends LightningElement {

    @api connectedSalesforceId;
    @api objectSetupId;
    cloneobjectSetupId ; //private variable to control the function call of getfieldSetupDetails()

    @track toggleSpinner = true;

    @track sourceunmappedLst;
    @track displayresult;
    @track destunmappedLst;

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
        let DestinationUpdatedList = this.destunmappedLst.filter(unit => unit.Destination_Object_Api_Name__c !== ev.dataTransfer.getData("text"));
        this.destunmappedLst = DestinationUpdatedList;
        this.sourceunmappedLst.map(function (unit) {
            if (unit != null || unit !== undefined) {
                if (unit.Name != null || unit.Name !== undefined) {
                    console.log(ev.currentTarget.childNodes[0].className);
                    if (ev.currentTarget.childNodes[0].className !== null) {
                        if (unit.Name === ev.currentTarget.childNodes[0].className) {
                            if(unit.Destination_Field_Api_Name__c !== "" || unit.Destination_Object_Api_Name__c !== " " ){
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
}