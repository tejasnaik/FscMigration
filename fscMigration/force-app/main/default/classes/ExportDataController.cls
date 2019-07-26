public class ExportDataController {
    
    @AuraEnabled
    public static List<Object_setup__c> getObjectSetupOptions(Id connectedSalesforceOrgId){
        System.debug('Connected salesforce org id @@@ ' + connectedSalesforceOrgId);
        List<Object_setup__c> objectSetUpLst = new List<Object_setup__c>();
        objectSetUpLst = [SELECT id,Name,Destination_Object_Name__c,SalesforceOrg__r.name
                          FROM Object_setup__c
                          WHERE id in (Select Object_setup_name__c from Field_setup__c  where Object_setup_name__r.SalesforceOrg__c =:connectedSalesforceOrgId)];

        return objectSetUpLst;
    }

    @AuraEnabled
    public static Id exportData(Id objectSetupRecordId,Id salesforceOrgId){
        system.debug('objectSetupRecordId @@@ ' + objectSetupRecordId);
        system.debug('salesforceOrgId @@@ ' + salesforceOrgId);
        Id batchJobId = Database.executeBatch(new BatchMigrateObject(salesforceOrgId,objectSetupRecordId));
        return  batchJobId;
        //return 'sucess';
    }

    @AuraEnabled
    public static AsyncApexJob getMigrateBatchStatus(Id batchJobId){
        System.debug('Batch Job id @@@ ' + batchJobId);
        List<AsyncApexJob> batchJobLst =  [SELECT JobItemsProcessed,ParentJobId,Status,TotalJobItems FROM AsyncApexJob where id=:batchJobId limit 1];
        return batchJobLst[0];
    }

    @AuraEnabled
    public static Batch_Transaction_Detail__c getBatchTransactionalDetails(Id batchId){
        
        List<Batch_Transaction_Detail__c> tranLst = [ SELECT Batch_Failed__c,Batch_Success__c,isSuccess__c,Object_setup_name__c,Total_Batch__c,Object_setup_name__r.Name,Object_setup_name__r.SalesforceOrg__r.Name  FROM Batch_Transaction_Detail__c where Batch_Id__c = :batchId limit 1];
        
        Batch_Transaction_Detail__c transobj = new Batch_Transaction_Detail__c();
        if(!tranLst.isEmpty() && tranLst.size() > 0){
            transobj = tranLst[0];       
        }
        return transobj;

    }
}
