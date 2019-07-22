public class ExportDataController {
    
    @AuraEnabled
    public static List<Object_setup__c> getObjectSetupOptions(Id connectedSalesforceOrgId){
        System.debug('Connected salesforce org id @@@ ' + connectedSalesforceOrgId);
        List<Object_setup__c> objectSetUpLst = new List<Object_setup__c>();
        objectSetUpLst = [SELECT id,Name,Destination_Object_Name__c
                          FROM Object_setup__c
                          WHERE id in (Select Object_setup_name__c from Field_setup__c  where Object_setup_name__r.SalesforceOrg__c =:connectedSalesforceOrgId)];

        return objectSetUpLst;
    }
}
