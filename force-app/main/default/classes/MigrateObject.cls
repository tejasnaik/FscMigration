public with sharing class MigrateObject {
   public class deserializeResponse{
        public String id;
        public String instance_url;
        public String access_token;
}
   
     public class oldid{
         public string id;
}

    public class newid{
        public string id;
        public boolean success;
}


@AuraEnabled
public static void migrateObjectDataInFSC(List<sObject> sobjList ,String authId,String objectsetupname, Map<String,String> fieldobjectmap){
// REST JSON INsert to Another ORG
//list<account> acc=[select id,name from Account limit 4];
//String fetchRecords ='Select'+FieldsName+'From'+ objectName;
// List<sObject> sobjList = Database.query(fetchRecords);
   
    String jsonResult=json.serialize(sobjList);
    List<oldid> oldids=(List<oldid>)(JSON.deserialize(jsonResult, List<oldid>.class));
    system.debug(oldids);
    jsonResult= '{ "records":'+jsonResult+'}';
    jsonResult=jsonResult.replaceAll('"url"', '"referenceId"');
    jsonResult=jsonResult.replaceAll('"Id":"[0-9a-zA-Z]{18}",','');
    jsonResult=jsonResult.replaceAll(',"CurrencyIsoCode":"INR"','');
    
    for(String sourcefield :fieldobjectmap.keyset()){
        string s='"'+sourcefield+'"';
        string d='"'+fieldobjectmap.get(sourcefield)+'"';
        jsonResult=jsonResult.replaceAll(s,d);
    }

    system.debug(jsonResult);
    List<newid> newids=(List<newid>)(JSON.deserialize(MigrateObject.createObjectDataInFSC(jsonResult,authId), List<newid>.class));
    system.debug(newids);
    List<Manage_Id__c> oldnewList=new List<Manage_Id__c>();
    //Map<String,String> oldnew=new Map<String,String>();
    
    for(Integer i=0 ;i<oldids.size(); i++){
    if(newids[i].success==true){
         //oldnew.put(oldids[i].id,newids[i].id);
         oldnewList[i]=new Manage_Id__c();
         oldnewList[i].Old_id__c=oldids[i].id;
         oldnewList[i].New_id__c=newids[i].id;
         oldnewList[i].Object_setup_name__c=objectsetupname;
         //oldnewList[i].isSuccess__c='true';
          
    }     
    else{
        oldnewList[i]=new Manage_Id__c();
        oldnewList[i].Old_id__c=oldids[i].id;
        oldnewList[i].Object_setup_name__c=objectsetupname;
        
    }    
  }
  insert oldnewList;

}


    @AuraEnabled
    public static String createObjectDataInFSC(String recordsinjson,String authId){
         // Getting Credential to Connect with Destination Org
         SalesforceOrg__c authClient=[Select Consumer_Key__c,Consumer_Secret__c,UserName__c,Password__c From SalesforceOrg__c where id =:authId limit 1];
   			 String returnString;
         String clientId =authClient.Consumer_Key__c;              
         String clientSecret =authClient.Consumer_Secret__c;         
   			 String username =authClient.UserName__c; 
    		 String password = authClient.Password__c;
			   String reqbody ='grant_type=password&client_id='+clientId+'&client_secret='+clientSecret+'&username='+username+'&password='+password;
      	// get Access token of Destination org
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setBody(reqbody);
        req.setMethod('POST');
        req.setEndpoint('https://login.salesforce.com/services/oauth2/token');
        HttpResponse res = h.send(req);
       	deserializeResponse response=(deserializeResponse)JSON.deserialize(res.getbody(),deserializeResponse.class);
        system.debug('Rest auth'+res.getbody());
        
        // API Call to Insertion
        
        String endPoint =response.instance_url+'/services/data/v45.0/composite/sObjects';   
		    
        if(response.access_token != null){
        HttpRequest httpRequest = new HttpRequest(); 
        httpRequest.setMethod('POST'); 
        String requestBody=recordsinjson;
        httpRequest.setHeader('Content-Type', 'application/json');
        httpRequest.setHeader('Accept', 'application/json');
        httpRequest.setHeader('Authorization', 'Bearer ' + response.access_token);
        httpRequest.setBody(requestBody);
        httpRequest.setEndpoint(endPoint); 
        Http ht = new Http();  
        HttpResponse httpResponse = ht.send(httpRequest); 
        system.debug('Body'+httpResponse.getBody());
        returnString = httpResponse.getBody();
     }
       return returnString;
    }
}
