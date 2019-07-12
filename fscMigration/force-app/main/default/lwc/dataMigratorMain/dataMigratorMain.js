/* eslint-disable no-console */
import { LightningElement, track, api } from 'lwc';

export default class DataMigratorMain extends LightningElement {

    @api connectedSalesforceOrgId;

    insertObjectSetup(){
        this.template.querySelector('c-setup-tab').nextButtonTriggered();
    }

    previousButtonTriggered(){
        this.template.querySelector('c-setup-tab').previousButtonTriggered();    
    }
}