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
            upsert objectSetupLst;
        }
        return 'success';
    }


    public Class ObjectSetUpWrapper{
        @AuraEnabled public List<Object_setup__c> mappedLst;
        @AuraEnabled public List<Object_setup__c> sourceunmappedLst;
        @AuraEnabled public List<Object_setup__c> destunmappedLst;
    }
	
}