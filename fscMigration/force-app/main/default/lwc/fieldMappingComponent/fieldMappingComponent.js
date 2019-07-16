import { LightningElement,api } from 'lwc';

export default class FieldMappingComponent extends LightningElement {

    @api connectedSalesforceId;
    @api objectSetupId;
    
}