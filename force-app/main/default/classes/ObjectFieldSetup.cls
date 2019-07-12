public Class ObjectFieldSetup{

    public static String instanceUrl;
    public static String access_Token;
    
    /*author: tejas
    * Parameter : Id for SalesforceOrg__C record  
    * return : Map with source object api name and dest object api name. 
    */

    @AuraEnabled
    public static ObjectFieldSetup.ObjectSetUpWrapper getObjectSetupWrapper(String salesforceOrgId){

        SalesforceOrg__c salesforceorg = new SalesforceOrg__c();
        if(salesforceOrgId != null){
            salesforceorg = [SELECT UserName__c,
                                    Password__c,
                                    Consumer_Key__c,
                                    Consumer_Secret__c,
                                    Type_Of_Org_Is_Sandbox__c
                             FROM  SalesforceOrg__c
                             WHERE id =:salesforceOrgId 
                             LIMIT 1];
            //String accessToken = getAccessToken(salesforceorg);                 
            populateAccessTokenandInsturl(salesforceorg);// to populate the class variables
            Map<String,String> sourceapi_labelObjectMap = getSourceObjects();
            Map<String,String> destapi_labelObjectMap = getFslObjects();

            List<Object_setup__c> mappedLst = new List<Object_setup__c>();
            List<Object_setup__c> sourceunmappedLst = new List<Object_setup__c>();
            List<Object_setup__c> destunmappedLst = new List<Object_setup__c>();

            for(String objapiname : sourceapi_labelObjectMap.keySet()){
                if(destapi_labelObjectMap.containsKey(objapiname)){
                    Object_setup__c mappedtemp = new Object_setup__c();
                    mappedtemp.SalesforceOrg__c = salesforceOrgId;
                    mappedtemp.Souce_Object_Api_Name__c = objapiname ;
                    mappedtemp.Name= sourceapi_labelObjectMap.get(objapiname);
                    mappedtemp.Destination_Object_Api_Name__c = objapiname;
                    mappedtemp.Destination_Object_Name__c = destapi_labelObjectMap.get(objapiname);
                    mappedLst.add(mappedtemp);
                    destapi_labelObjectMap.remove(objapiname);        
                }else{
                    Object_setup__c sourceunmappedtemp = new Object_setup__c();
                    sourceunmappedtemp.SalesforceOrg__c = salesforceOrgId;
                    sourceunmappedtemp.Souce_Object_Api_Name__c = objapiname ;
                    sourceunmappedtemp.Name= sourceapi_labelObjectMap.get(objapiname);
                    sourceunmappedtemp.Destination_Object_Api_Name__c = '';
                    sourceunmappedtemp.Destination_Object_Name__c = '';
                    sourceunmappedLst.add(sourceunmappedtemp);
                }    
            }

            for(String objapiname : destapi_labelObjectMap.keySet()){
                Object_setup__c destunmappedtemp = new Object_setup__c();
                destunmappedtemp.SalesforceOrg__c = salesforceOrgId;
                destunmappedtemp.Souce_Object_Api_Name__c = '' ;
                destunmappedtemp.Name= '';
                destunmappedtemp.Destination_Object_Api_Name__c = objapiname;
                destunmappedtemp.Destination_Object_Name__c = destapi_labelObjectMap.get(objapiname);
                destunmappedLst.add(destunmappedtemp);
            }

            ObjectSetUpWrapper objwrapper = new ObjectSetUpWrapper();
            objwrapper.mappedLst = mappedLst;
            objwrapper.sourceunmappedLst = sourceunmappedLst;
            objwrapper.destunmappedLst = destunmappedLst;    
            return objwrapper;

        }//end of salesforceorgid null check     

        return null;
    }// end of getObjectSetupWrapper

    public static void populateAccessTokenandInsturl(SalesforceOrg__c salesforceorgObj){
        String reqbody = 'grant_type=password&client_id='+salesforceorgObj.Consumer_Key__c+'&client_secret='+salesforceorgObj.Consumer_Secret__c+'&username='+salesforceorgObj.UserName__c+'&password='+salesforceorgObj.Password__c;
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setHeader('content-type','application/x-www-form-urlencoded');
        req.setMethod('POST');
        if(salesforceorgObj.Type_Of_Org_Is_Sandbox__c == true)
            req.setEndpoint('https://test.salesforce.com/services/oauth2/token?');
        else
            req.setEndpoint('https://login.salesforce.com/services/oauth2/token?');

        req.setBody(reqbody);
        HttpResponse res = h.send(req);
        system.debug('Access token res>>>>>>>>>>>>>'+res.getBody());
        String resbody = res.getBody();
        Map<String,Object> response = (Map<String,Object>)JSON.deserializeUntyped(resbody);
        System.debug('Access token Response status @@@@ ' + res.getStatus());
        System.debug('Access token Response status code @@@@ ' + res.getStatusCode());
        if(res.getStatusCode() == 200){
            access_Token = (String)response.get('access_token');
            instanceUrl = (String)response.get('instance_url');
        }else{
            System.debug('Failed to fetch access token');
        }
    }

    public static Map<String,String> getSourceObjects(){

        Map<String,String> sourceapi_labelObjectMap = new Map<String,String>();
        List<String> stdObjectLst = new List<String>{'Account','Contact','Lead','Opportunity','AccountContactRole','Product2','Asset','Order','OrderItem','Pricebook2','PricebookEntry','OpportunityLineItem','Quote','QuoteLineItem'};
        Map<String,Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe();
        for(Schema.SObjectType objectType : globalDescribeMap.values()) {
            Schema.DescribeSObjectResult sobjectResult = objectType.getDescribe();
            if(stdObjectLst.contains(sobjectResult.getName()) ||  sobjectResult.getName().endsWith('__c')){
                //System.debug('Label @@@ ' + sobjectResult.getLabel());
                //System.debug('Name @@@ ' + sobjectResult.getName());
                sourceapi_labelObjectMap.put(sobjectResult.getName(),sobjectResult.getLabel());
            }
            
        }//end of for
        return sourceapi_labelObjectMap;
    }

    public static Map<String,String> getFslObjects(){
        Map<String,String> destapi_labelObjectMap = new Map<String,String>();

        System.debug('Access token @@@ ' + access_Token);
        System.debug('Instance url @@@ ' + instanceUrl);

        String endpoint = instanceUrl + '/services/data/v40.0/sobjects';
        HTTPRequest req = new HTTPRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + access_Token);
        req.setHeader('Content-Type', 'application/json');
        Http ht = new Http();
        HttpResponse responseobjects = ht.send(req);
        System.debug('Status code @@@ ' + responseobjects.getStatusCode());
        System.debug('Response body code @@@ ' + responseobjects.getBody());
        Map<String,Object> responseMap = (Map<String,Object>)JSON.deserializeUntyped(responseobjects.getBody());
        List<Object> objectLst = (List<Object>)responseMap.get('sobjects');
        System.debug('object lst size @@@  ' + objectLst.size());
        List<String> stdObjLst = new List<String>{'Account','Contact','Lead','Opportunity','FinServ__FinancialAccount__c','FinServ__FinancialAccountRole__c','FinServ__FinancialAccountTransaction__c','FinServ__Card__c','FinServ__Revenue__c','FinServ__BillingStatement__c','FinServ__AssetsAndLiabilities__c','FinServ__ChargesAndFees__c','FinServ__FinancialHolding__c','FinServ__Securities__c','FinServ__FinancialGoal__c'};
        List<Map<String,String>> resultLst = new List<Map<String,String>>();

        for(Object obj : objectLst){
            Map<String,Object> objinfo = (Map<String,Object>)obj;
            if(stdObjLst.contains((String)objinfo.get('name'))){
                destapi_labelObjectMap.put((String)objinfo.get('name'),(String)objinfo.get('label'));            
            }
        }


        return destapi_labelObjectMap;
    }

    @AuraEnabled
    public static String objectSetupInsertion(List<Object_setup__c> objectSetupLst){
        System.debug('Object setup list @@@@ ' + objectSetupLst.size());
        if(objectSetupLst.size() > 0){
            upsert objectSetupLst Souce_Object_Api_Name__c;
        }
        return 'success';
    }

    /*Author: Pratiksha Gupta
    * Parameter : Id for SalesforceOrg__C record  
    * return : Map Fields with source object api name and dest object api name. 
    */

    

    //Begin FieldSetup Wrapper 
    @AuraEnabled
    public static ObjectFieldSetup.FieldtSetUpWrapper getFieldSetUpWrapper(String salesforceOrgId,String objectsetupid){

          SalesforceOrg__c salesforceorg = new SalesforceOrg__c();
        if(salesforceOrgId != null){
            salesforceorg = [SELECT UserName__c,
                                    Password__c,
                                    Consumer_Key__c,
                                    Consumer_Secret__c,
                                    Type_Of_Org_Is_Sandbox__c
                             FROM  SalesforceOrg__c
                             WHERE id =:salesforceOrgId 
                             LIMIT 1];
            //String accessToken = getAccessToken(salesforceorg);                 
            populateAccessTokenandInsturl(salesforceorg);// to populate the class variables
            Map<String,String> sourceapi_labelFieldMap = getSourceFields(objectsetupid);
            Map<String,String> destapi_labelFieldMap = getFslFields(objectsetupid);
            system.debug(sourceapi_labelFieldMap);
            system.debug(destapi_labelFieldMap);
            List<Field_setup__c> mappedLst = new List<Field_setup__c>();
            List<Field_setup__c> sourceunmappedLst = new List<Field_setup__c>();
            List<Field_setup__c> destunmappedLst = new List<Field_setup__c>();

            for(String objapiname : sourceapi_labelFieldMap.keySet()){
                if(destapi_labelFieldMap.containsKey(objapiname)){
                   Field_setup__c mappedtemp =new Field_setup__c();
                   mappedtemp.Name=sourceapi_labelFieldMap.get(objapiname);
                   mappedtemp.Souce_Field_Api_Name__c=objapiname;
                   mappedtemp.Destination_Field_Name__c=objapiname;
                   mappedtemp.Destination_Field_Api_Name__c=destapi_labelFieldMap.get(objapiname);
                   mappedtemp.Object_setup_name__c=salesforceOrgId;
                   mappedLst.add(mappedtemp);
                   destapi_labelFieldMap.remove(objapiname);
                
                }else{

                   Field_setup__c mappedtemp =new Field_setup__c();
                   mappedtemp.Name=sourceapi_labelFieldMap.get(objapiname);
                   mappedtemp.Souce_Field_Api_Name__c=objapiname;
                   mappedtemp.Destination_Field_Name__c='';
                   mappedtemp.Destination_Field_Api_Name__c='';
                   mappedtemp.Object_setup_name__c=salesforceOrgId;
                   sourceunmappedLst.add(mappedtemp);
                    
                }    
            }

            for(String objapiname : destapi_labelFieldMap.keySet()){
                 Field_setup__c mappedtemp =new Field_setup__c();
                   mappedtemp.Name='';
                   mappedtemp.Souce_Field_Api_Name__c='';
                   mappedtemp.Destination_Field_Name__c=objapiname;
                   mappedtemp.Destination_Field_Api_Name__c=destapi_labelFieldMap.get(objapiname);
                   mappedtemp.Object_setup_name__c=salesforceOrgId;
                   destunmappedLst.add(mappedtemp);
            }

            FieldtSetUpWrapper fldwrapper = new FieldtSetUpWrapper();
            fldwrapper.mappedLst = mappedLst;
            fldwrapper.sourceunmappedLst = sourceunmappedLst;
            fldwrapper.destunmappedLst = destunmappedLst;    
            return fldwrapper;
           

        }//end of salesforceorgid null check     
    
        return null;
    
} //End FieldSetup Wrapper


    public static Map<String,String> getSourceFields(String objectsetupid){

        
        Object_setup__c sourceobjecapiname=[SELECT Souce_Object_Api_Name__c FROM Object_setup__c where Id =: objectsetupid];
        Map<String,String> sourceapi_labelfieldMap = new Map<String,String>();

        
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(sourceobjecapiname.Souce_Object_Api_Name__c).getDescribe().fields.getMap();
        
        for (String fieldName: fieldMap.keySet()) {
           //System.debug('##Field API Name='+fieldName);// list of all field API name
           //System.debug('field name label'+fieldMap.get(fieldName).getDescribe().getLabel());//It provides to get the object fields label.
            sourceapi_labelfieldMap.put(fieldName,fieldMap.get(fieldName).getDescribe().getLabel());

        }//end of for
        return sourceapi_labelfieldMap;
    } // End source Field Fetch

    public static Map<String,String> getFslFields(String objectsetupid){
        
        Object_setup__c destinationobjectapiname=[SELECT Destination_Object_Api_Name__c FROM Object_setup__c where Id =: objectsetupid];
        
        Map<String,String> destapi_labelFieldMap = new Map<String,String>();

        System.debug('Access token @@@ ' + access_Token);
        System.debug('Instance url @@@ ' + instanceUrl);

        String endpoint = instanceUrl + '/services/data/v45.0/sobjects/'+destinationobjectapiname.Destination_Object_Api_Name__c+'/describe';
        HTTPRequest req = new HTTPRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + access_Token);
        req.setHeader('Content-Type', 'application/json');
        Http ht = new Http();
        HttpResponse responseobjects = ht.send(req);
        System.debug('Response body code @@@ ' + responseobjects.getBody());
        
        Map<String,Object> responseMap = (Map<String,Object>)JSON.deserializeUntyped(responseobjects.getBody());
        List<Object> objectLst = (List<Object>)responseMap.get('fields');
       
		System.debug('Response body code @@@ ' + objectLst);
 		for(Object obj : objectLst){
            Map<String,Object> objinfo = (Map<String,Object>)obj;
            String name=(String)objinfo.get('name');
            String label=(String)objinfo.get('label');
            destapi_labelFieldMap.put(name.toLowerCase(),label);
        }


        return destapi_labelFieldMap;
    } //End FSL Field Fetch

    public Class FieldtSetUpWrapper{
        @AuraEnabled public List<Field_setup__c> mappedLst;
       @AuraEnabled public List<Field_setup__c> sourceunmappedLst;
      @AuraEnabled  public List<Field_setup__c> destunmappedLst;
    }



    public Class ObjectSetUpWrapper{
        @AuraEnabled public List<Object_setup__c> mappedLst;
        @AuraEnabled public List<Object_setup__c> sourceunmappedLst;
        @AuraEnabled public List<Object_setup__c> destunmappedLst;
    }
	
}