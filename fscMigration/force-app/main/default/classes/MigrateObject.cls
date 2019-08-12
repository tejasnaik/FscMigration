public with sharing class MigrateObject {
public class deserializeResponse {
public String id;
public String instance_url;
public String access_token;
}

public class oldid {
public string id;
}

public class newid {
public string id;
public boolean success;
public errorWrapper[] errors;
}

public class errorWrapper{
	public string message;
	public string statusCode;
}

@AuraEnabled
public static void migrateObjectDataInFSC(List<sObject> sobjList,String authId,String objectsetupname, Map<String,String> fieldobjectmap){
	//Separate the data into create and update list
    List<sObject> updateSobjectLst = new List<sObject>();// will contain records which needs be updated
    List<sObject> insertSobjectLst = new List<sObject>();// will contain records which needs be inserted

    String sobjListserialized = json.serialize(sobjList);
    List<Id> recordsIds = new List<Id>();
    for(sObject record : sobjList){
        recordsIds.add((Id)record.get('Id'));    
    }
    Map <Id,Manage_Id__c> recordId_manage = new Map<Id,Manage_Id__c>();
    List<Manage_Id__c> manageobjlst = [Select Old_id__c,New_id__c from Manage_Id__c where Old_id__c in :recordsIds];
    System.debug('manage objlist size @@@  '  + manageobjlst.size());
    for(Manage_Id__c manageObj : [Select Old_id__c,New_id__c,Status__c from Manage_Id__c where Old_id__c in :recordsIds]){
        recordId_manage.put(manageObj.Old_id__c,manageObj);
    }    
    for(Integer i= 0 ;i<sobjList.size(); i++){
        if(recordId_manage.containsKey((Id)sobjList[i].get('Id')) && recordId_manage.get((Id)sobjList[i].get('Id')).New_id__c != null){
            updateSobjectLst.add(sobjList[i]);
        }else{
            insertSobjectLst.add(sobjList[i]);
        }
    }
    System.debug('Update record listsize  @@@ '  + updateSobjectLst.size());
    System.debug('insert record list size @@@@'  + insertSobjectLst.size());
	List<Manage_Id__c> updatemanagelst = updateObjectDatainFsc(updateSobjectLst,authId,manageobjlst,fieldobjectmap);
    // new code end 
    //Map<Id,Id> oldId_newIdMap = populateLookUpIdMap(objectsetupname,sobjList);
	//String jsonResult=json.serialize(sobjList);
    Map<Id,Id> oldId_newIdMap = populateLookUpIdMap(objectsetupname,insertSobjectLst);
	String jsonResult=json.serialize(insertSobjectLst);
	System.debug(jsonResult);
	List<oldid> oldids=(List<oldid>)(JSON.deserialize(jsonResult, List<oldid>.class));
    system.debug('Oldids @@@ ');
	system.debug(oldids);
	system.debug(fieldobjectmap);
	jsonResult= '{ "records":'+jsonResult+'}';
	jsonResult=jsonResult.replaceAll('"url"', '"referenceId"');
	jsonResult=jsonResult.replaceAll('"Id":"[0-9a-zA-Z]{18}",','');
	jsonResult=jsonResult.replaceAll(',"CurrencyIsoCode":"INR"','');

	for(String sourcefield :fieldobjectmap.keyset()) {
		string s='"'+sourcefield+'"';
		string d='"'+fieldobjectmap.get(sourcefield)+'"';
		jsonResult=jsonResult.replaceAll(s,d);
	}
	for(Id oldrecid : oldId_newIdMap.keyset()) {
		string s='"'+oldrecid+'"';
		string d='"'+oldId_newIdMap.get(oldrecid)+'"';
		jsonResult=jsonResult.replaceAll(s,d);
	}
	system.debug('@@@@ json result sss @@@@@ ');
	system.debug(jsonResult);
	
    List<newid> newids=(List<newid>)(JSON.deserialize(MigrateObject.createObjectDataInFSC(jsonResult,authId), List<newid>.class));
	system.debug(newids);
	List<Manage_Id__c> oldnewList=new List<Manage_Id__c>();
	List<Manage_Id__c> updateoldnewList = new List<Manage_Id__c>();

	for(Integer i=0; i<oldids.size(); i++) {
		if(newids[i].success==true) {
			if(recordId_manage.containsKey((Id)oldids[i].id)){
				Manage_Id__c managerec = recordId_manage.get((Id)oldids[i].id);
				managerec.New_id__c = newids[i].id;
				updateoldnewList.add(managerec);
			}else{
				Manage_Id__c manageSuccessObj = new Manage_Id__c();
				manageSuccessObj.Old_id__c = oldids[i].id;
				manageSuccessObj.New_id__c = newids[i].id;
				manageSuccessObj.Object_setup_name__c = objectsetupname;
				manageSuccessObj.Status__c = 'Success';
				oldnewList.add(manageSuccessObj);
			}
			
		}
		else{
			if(recordId_manage.containsKey((Id)oldids[i].id)){
				Manage_Id__c managerec = recordId_manage.get((Id)oldids[i].id);
				managerec.Status__c = '';
				for(errorWrapper error :newids[i].errors){
					managerec.Status__c = managerec.Status__c + error.statusCode + ' ' + error.message;
					updateoldnewList.add(managerec); 
				}
			}else{
				Manage_Id__c manageFailObj = new Manage_Id__c();
				manageFailObj.Old_id__c=oldids[i].id;
				manageFailObj.Object_setup_name__c = objectsetupname;
				for(errorWrapper error :newids[i].errors){
					manageFailObj.Status__c = manageFailObj.Status__c + error.statusCode + ' ' + error.message;
				}
				oldnewList.add(manageFailObj);
			}
			
		}
	}
	insert oldnewList;
	if(!updateoldnewList.isEmpty()){
		update updateoldnewList;
	}
	if(!updatemanagelst.isEmpty()){
		update updatemanagelst;
	}

}


@AuraEnabled
public static String createObjectDataInFSC(String recordsinjson,String authId){
	// // Getting Credential to Connect with Destination Org
	// SalesforceOrg__c authClient=[Select Consumer_Key__c,Consumer_Secret__c,UserName__c,Password__c From SalesforceOrg__c where id =:authId limit 1];
	// String returnString;
	// String clientId =authClient.Consumer_Key__c;
	// String clientSecret =authClient.Consumer_Secret__c;
	// String username =authClient.UserName__c;
	// String password = authClient.Password__c;
	// String reqbody ='grant_type=password&client_id='+clientId+'&client_secret='+clientSecret+'&username='+username+'&password='+password;
	// // get Access token of Destination org
	// Http h = new Http();
	// HttpRequest req = new HttpRequest();
	// req.setBody(reqbody);
	// req.setMethod('POST');
	// req.setEndpoint('https://login.salesforce.com/services/oauth2/token');
	// HttpResponse res = h.send(req);
	//deserializeResponse response=(deserializeResponse)JSON.deserialize(res.getbody(),deserializeResponse.class);
	String returnString;
	deserializeResponse response = getAccessToken(authId);
	//system.debug('Rest auth'+res.getbody());

	// API Call to Insertion

	String endPoint =response.instance_url+'/services/data/v45.0/composite/sObjects';

	if(response.access_token != null) {
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
		System.debug('Status @@  ' + httpResponse.getStatus());
		System.debug('Status code @@  ' + httpResponse.getStatusCode());
		system.debug('Body'+httpResponse.getBody());
		returnString = httpResponse.getBody();
		
	}
	return returnString;
}

public static Map<Id,Id> populateLookUpIdMap(String objectSetUpID,List<sObject> sobjList){
	map<Id,Id> oldId_newIdMap = new Map<Id,Id>();
	List<StandardFields__mdt> standardFieldmdt = new List<StandardFields__mdt>();
	Set<Id> oldIds = new Set <Id>();
	//List<Manage_Id__c> managelst = new List<Manage_Id__c>();

	if(!String.isBlank(objectSetUpID)) {
		Object_setup__c objsetup = [Select Souce_Object_Api_Name__c from Object_setup__c where id =:objectSetUpID];
		standardFieldmdt = [Select FieldApiName__c,LookupFieldApiName__c,DeveloperName from StandardFields__mdt where DeveloperName = :objsetup.Souce_Object_Api_Name__c];

	}//end of if isblank
	if(standardFieldmdt != null && standardFieldmdt.size() >0) {
		StandardFields__mdt selectedObj = standardFieldmdt[0];
		List<String> lookupfieldnamelst = new List<String> ();
		if(String.isNotBlank(selectedObj.LookupFieldApiName__c)) {
			lookupfieldnamelst = selectedObj.LookupFieldApiName__c.split(',');
		}
		for(String lookupfieldname:lookupfieldnamelst) {
			for(Sobject obj :sobjList) {
				oldIds.add((Id)obj.get(lookupfieldname));
			}
		}//end of for
		if(!oldIds.isEmpty()) {
			//managelst = [Select New_id__c,Old_id__c from Manage_Id__c where Old_id__c in :oldIds];
			for(Manage_Id__c managerec : [Select New_id__c,Old_id__c from Manage_Id__c where Old_id__c in :oldIds]) {
				//verify if we need to check if new id needs to be checked for null
				oldId_newIdMap.put(managerec.Old_id__c,managerec.New_id__c);
			}
		}
	}

	return oldId_newIdMap;
}

public static deserializeResponse getAccessToken(String salesforceOrgId){
	if(String.isNotBlank(salesforceOrgId)){
		SalesforceOrg__c authClient=[Select Consumer_Key__c,Consumer_Secret__c,UserName__c,Password__c From SalesforceOrg__c where id =:salesforceOrgId limit 1];
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
		deserializeResponse deserializeResponse=(deserializeResponse)JSON.deserialize(res.getbody(),deserializeResponse.class);
		System.debug('deserializeResponse accesstoken '  + deserializeResponse.access_token);
		System.debug('deserializeResponse instance url ' + deserializeResponse.instance_url);

		return deserializeResponse;	
	}

	return null;
}

public static List<Manage_Id__c> updateObjectDatainFsc(List<sObject> updatesObjectData,String salesforceOrgId ,List<Manage_Id__c > manageRecordLst,Map<String,String> fieldobjectmap){
	List<Manage_Id__c> managelstupdlst = new List<Manage_Id__c>();
	if(!updatesObjectData.isEmpty()){
		deserializeResponse deserializeResponse = getAccessToken(salesforceOrgId);
		String serializedData=json.serialize(updatesObjectData);
		List<oldid> updateoldids=(List<oldid>)(JSON.deserialize(serializedData, List<oldid>.class));
		List<Id> oldid = new List<Id>();
		Map<Id,Manage_Id__c> oldId_Managemap = new Map<Id,Manage_Id__c>();
		for(oldid oldidrecord : updateoldids){
			oldid.add((Id)oldidrecord.id);	
		}
		for(Manage_Id__c manageRecord : [ SELECT New_id__c,Object_setup_name__c,Old_id__c,Status__c FROM Manage_Id__c where Old_id__c  in :oldid]){
			System.debug(manageRecord);
			oldId_Managemap.put(manageRecord.Old_id__c,manageRecord);
		}
		serializedData= '{ "records":'+serializedData+'}';
		for(Manage_Id__c manageRecord : manageRecordLst){
			string s='"'+manageRecord.Old_id__c+'"';
            string d='"'+manageRecord.New_id__c +'"';
            serializedData=serializedData.replaceAll(s,d);	
		}
		for(String sourcefield :fieldobjectmap.keyset()) {
			string s='"'+sourcefield+'"';
			string d='"'+fieldobjectmap.get(sourcefield)+'"';
			serializedData=serializedData.replaceAll(s,d);
		}
		String endPoint =deserializeResponse.instance_url+'/services/data/v45.0/composite/sObjects'+'?_HttpMethod=PATCH';
		HttpRequest httpRequest = new HttpRequest(); 
        httpRequest.setMethod('POST'); 
		String requestBody=serializedData;
		httpRequest.setHeader('Content-Type', 'application/json');
        httpRequest.setHeader('Accept', 'application/json');
        httpRequest.setHeader('Authorization', 'Bearer ' + deserializeResponse.access_token);
        httpRequest.setBody(requestBody);
        httpRequest.setEndpoint(endPoint);
		Http ht = new Http();  
        HttpResponse httpResponse = ht.send(httpRequest);
        System.debug('Status for update @@  ' + httpResponse.getStatus());
        System.debug('Status code for update  @@  ' + httpResponse.getStatusCode()); 
        system.debug('Body of update '+httpResponse.getBody());
		String updatedResponseString = 	 httpResponse.getBody();
		System.debug('updatedResponseString @@@@ ' + updatedResponseString);
		List<newid> updatenewids=(List<newid>)(JSON.deserialize(updatedResponseString, List<newid>.class));
		System.debug('New Ids list size @@@ ' + updatenewids.size());
		System.debug('Old ids list size @@@ ' + updateoldids.size());
		for(integer i= 0 ;i<updatenewids.size();i++){
			System.debug('new id ' + updatenewids[i]);
			System.debug('old id ' + updateoldids[i]);
			Manage_Id__c manage = new Manage_Id__c();
			if(oldId_Managemap.containsKey((Id)updateoldids[i].id)){
				manage =  oldId_Managemap.get((Id)updateoldids[i].id);
			}
			if(updatenewids[i].success == true){
				manage.Status__c = 'Success';
					
			}else{
				System.debug(updatenewids[i].errors);
				manage.Status__c = '';
				for(errorWrapper error : updatenewids[i].errors){
					manage.Status__c = manage.Status__c +''+error.statusCode + ' ' + error.message;
					System.debug('Status code @@@@' + error.statusCode);
					System.debug('Message @@@  ' + error.message);
				}

			}
			managelstupdlst.add(manage);
		}

		//update managelstupdlst;
	}
	return managelstupdlst;
}
}
