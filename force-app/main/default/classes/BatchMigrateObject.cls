global with sharing class BatchMigrateObject implements Database.Batchable<sObject> {
    String objectsetupname;
    String query;
    String authId;
    Map<String,String> fieldobjectmap;
    
    global BatchMigrateObject(String authId,String objectsetupname) {
        this.objectsetupname=objectsetupname;
        this.authId=authId;
        String sourcefieldName='Id,';

        Object_setup__c objectName=[SELECT Destination_Object_Api_Name__c,Souce_Object_Api_Name__c FROM Object_setup__c WHERE Id =:objectsetupname LIMIT 1];
        List<Field_setup__c> fieldName=[SELECT Destination_Field_Api_Name__c,Souce_Field_Api_Name__c FROM Field_setup__c WHERE Object_setup_name__c=:objectsetupname ];
        Map<String,String> fieldobjectmap=new Map<String,String>();
        
        if(objectName.Souce_Object_Api_Name__c!=objectName.Destination_Object_Api_Name__c){
           fieldobjectmap.put(objectName.Souce_Object_Api_Name__c,objectName.Destination_Object_Api_Name__c);
        }
       
        for(Field_setup__c fn:fieldName){
           sourcefieldName=sourcefieldName+fn.Souce_Field_Api_Name__c+',';
           if(fn.Destination_Field_Api_Name__c!=fn.Souce_Field_Api_Name__c){
               fieldobjectmap.put(fn.Souce_Field_Api_Name__c,fn.Destination_Field_Api_Name__c);
           }
         }
         
        sourcefieldName=sourcefieldName.removeEnd(',');
        this.query='SELECT'+sourcefieldName+'FROM'+ objectName.Souce_Object_Api_Name__c;

    }

   global Database.QueryLocator start(Database.BatchableContext BC){
      return Database.getQueryLocator(query);
   }

   global void execute(Database.BatchableContext BC, List<sObject> sobjList){
      MigrateObject.migrateObjectDataInFSC(sobjList,authId,objectsetupname,fieldobjectmap);
   }

   global void finish(Database.BatchableContext BC){
      AsyncApexJob a = [Select a.TotalJobItems, a.NumberOfErrors,a.JobItemsProcessed From AsyncApexJob a WHERE id = :BC.getJobId()];
      Batch_Transaction_Detail__c newBatch=new Batch_Transaction_Detail__c();
      newBatch.Batch_Failed__c= a.NumberOfErrors;
      newBatch.Batch_Id__c=BC.getJobId();
      newBatch.Batch_Success__c=a.JobItemsProcessed;
      newBatch.Object_setup_name__c=objectsetupname;
      newBatch.Total_Batch__c=a.TotalJobItems;

      insert newBatch;

   }

}
