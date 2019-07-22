import { LightningElement,api,track } from 'lwc';
import getObjectSetupOptions from '@salesforce/apex/ExportDataController.getObjectSetupOptions';

export default class ExportData extends LightningElement {

    @api exportDataConnectedSalesforceOrgId;
    @track value = '';
    @track objectSetupOptLst = [];
    @track objectSetupLst;


    renderedCallback(){
        console.log('rendered callback export data  called');
        this.objsetupoptions();
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
                // var setupobj = new Object();
                // setupobj.label = item.Name;
                // setupobj.value = item.Destination_Object_Name__c;
                // console.log(item.Name);
                // console.log(item.Destination_Object_Name__c);
                // self.objectSetupOptLst.push(setupobj);
              });
              console.log(this.objectSetupOptLst);
        })
        .catch(error =>{
            console.log('error in get options list');
            console.log(error);
        })
        //return this.objectSetupOptLst;
        
    }

    get objoptions(){
        // console.log('get objotions ');
        // console.log(this.objectSetupOptLst.length);
        // return this.objectSetupOptLst;
        // this.objectSetupOptLst = [
        //     { label: 'New', value: 'new' },
        //     { label: 'In Progress', value: 'inProgress' },
        //     { label: 'Finished', value: 'finished' },
        // ]
        return this.objectSetupOptLst;
    }
    handleObjectChange(event) {
        //this.value = event.detail.value;
    }
}