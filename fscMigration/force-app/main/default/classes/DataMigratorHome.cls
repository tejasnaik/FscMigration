public with sharing class DataMigratorHome {

    public static String instanceUrl;
    public static String access_Token;

    @AuraEnabled(cacheable = true)
    public static List<SalesforceOrg__c> getConnetecSaleforceOrg(){
        List<SalesforceOrg__c> salesforceOrgLst = new List<SalesforceOrg__c>();
        salesforceOrgLst = [Select Name, Id FROM SalesforceOrg__c Limit 20];
        return salesforceOrgLst;                    

    }

    /*
    * Method to validate the salesforce org connection credentials
    * If successfull save a record  within the SalesforceOrg__c Object
    * else send a failure message.
    */
    @AuraEnabled
    public static string validateConnection(String orgName,String userName,String pwd,String clientid,String clientsecret,boolean typeOfOrgIsSandbox){

        String message ;
        message = getAccessToken(userName,pwd,clientid,clientsecret,typeOfOrgIsSandbox);
        if(!message.equals('Failed')){
            message = 'Success';
            SalesforceOrg__c org = new SalesforceOrg__c();
            org.Name = orgName;
            org.UserName__c = userName;
            org.Password__c = pwd;
            org.Consumer_Key__c = clientid;
            org.Consumer_Secret__c = clientsecret;
            org.Type_Of_Org_Is_Sandbox__c = typeOfOrgIsSandbox;
            insert org;
        }//end of success if

        return message;
    } 

    @AuraEnabled
    public static ObjectListWrapper getFSLObjects(Id salesforceOrgId){
        
        System.debug('Salesforce org id @@@ ' + salesforceOrgId);
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
        }
        getAccessToken(salesforceorg.UserName__c,salesforceorg.Password__c,salesforceorg.Consumer_Key__c,salesforceorg.Consumer_Secret__c,salesforceorg.Type_Of_Org_Is_Sandbox__c);
        
        Map<String,String> StdObjapiName_LabelMap = getSourceOrgObject();
        Map<String,String> FSObjapiName_LabelMap = new Map<String,String>();
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
                //FSObjapiName_LabelMap.put((String)objinfo.get('name'),(String)objinfo.get('label'));            
                Map<String,String> temmap = new Map<String,String>();
                temmap.put('label',(String)objinfo.get('label'));
                temmap.put('value',(String)objinfo.get('name'));
                resultLst.add(temmap);
            }
        }
        ObjectListWrapper wrapper = new ObjectListWrapper();
        wrapper.stdObjectLst = StdObjapiName_LabelMap.values();
        wrapper.fslPickList = resultLst;

        return  wrapper;
        //return 'Success';
    }//end of getFSLObjects

    public static String getAccessToken(String userName,String pwd,String clientid,String clientsecret,boolean typeOfOrgIsSandbox){
        String message;
        String reqbody = 'grant_type=password&client_id='+clientId+'&client_secret='+clientSecret+'&username='+username+'&password='+pwd;
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setHeader('content-type','application/x-www-form-urlencoded');
        req.setMethod('POST');
        if(typeOfOrgIsSandbox == true)
            req.setEndpoint('https://test.salesforce.com/services/oauth2/token?');
        else
            req.setEndpoint('https://login.salesforce.com/services/oauth2/token?');

        req.setBody(reqbody);
        HttpResponse res = h.send(req);
        system.debug('res>>>>>>>>>>>>>'+res.getBody());
        String resbody = res.getBody();
        Map<String,Object> response = (Map<String,Object>)JSON.deserializeUntyped(resbody);
        System.debug('Response status @@@@ ' + res.getStatus());
        System.debug('Response status code @@@@ ' + res.getStatusCode());
        if(res.getStatusCode() == 200){
            access_Token = (String)response.get('access_token');
            instanceUrl = (String)response.get('instance_url');
            message = 'Success';
        }else{
            message = 'Failed';
        }

        return message;    
    }

    public static Map<String,String> getSourceOrgObject(){
        Map<String,String> apiName_LabelMap = new Map <String,String>();
        //Harcoded list of standard objects from source org
        //List<String> stdObjectLst = new List<String>{'Account','Contact','Lead','Opportunity','AccountContactRole','Product2','Asset','Order','OrderItem','Pricebook2','PricebookEntry','OpportunityLineItem','Quote','QuoteLineItem'};
        List<String> stdObjectLst = new List<String>{'Account'};
        Map<String,Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe();
        AggregateResult[] groupedResults = [SELECT NamespacePrefix FROM PackageLicense group by NamespacePrefix];
        AggregateResult[] groupedResultsObjectName = [SELECT SobjectType FROM ObjectPermissions group by SobjectType];
        set<String> namespaceValues = new set<String>();
        set<String> ObjectNameValues = new set<String>();
        for (AggregateResult ar : groupedResults)  {
            namespaceValues.add(ar.get('NamespacePrefix')+'');
        }
        for (AggregateResult ar : groupedResultsObjectName){
            ObjectNameValues.add(ar.get('SobjectType')+'');
        }
        for(Schema.SObjectType objectType : globalDescribeMap.values()) {
            Schema.DescribeSObjectResult sobjectResult = objectType.getDescribe();
            if(stdObjectLst.contains(sobjectResult.getName()) ||  sobjectResult.getName().endsWith('__c')){
                System.debug('Label @@@ ' + sobjectResult.getLabel());
                System.debug('Name @@@ ' + sobjectResult.getName());
                apiName_LabelMap.put(sobjectResult.getName(),sobjectResult.getLabel());
            }
            
        }//end of for 

        return apiName_LabelMap;
    }//end of getSourceOrgObject
 
}