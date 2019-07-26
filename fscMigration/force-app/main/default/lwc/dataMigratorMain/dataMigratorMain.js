/* eslint-disable no-console */
import { LightningElement, track, api,wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsub';
import getMigrateBatchStatus from '@salesforce/apex/ExportDataController.getMigrateBatchStatus';
import getBatchTransactionalDetails from '@salesforce/apex/ExportDataController.getBatchTransactionalDetails'
//import { CurrentPageReference } from 'lightning/navigation';

export default class DataMigratorMain extends LightningElement {

    @api connectedSalesforceOrgId;
    @wire(CurrentPageReference) pageRef;
    @track activeTabValue = 'Setup';

    //progress bar variables
    @track progressBarValue = 0;
    @track totalJobItems = 0;
    @track jobItemsProcessed = 0;
    @track jobStatus;
    @track progressText = 'Processing...';

    //Batch Transaction object
    @track transactionDetailObj;

    @track objectName;
    @track salesforceOrgName;
    @track jobItemsProcessedDetail;
    @track totalJobItemsDetail;
    @track failedJobitemsDetail;

    connectedCallback() {
        // subscribe to searchKeyChange event
        registerListener('activateTransactionTab', this.activateTransactionTab, this);
    }

    insertObjectSetup(){
        this.template.querySelector('c-setup-tab').nextButtonTriggered();
    }

    previousButtonTriggered(){
        this.template.querySelector('c-setup-tab').previousButtonTriggered();    
    }

    activateTransactionTab(jsObj){
        console.log('Activaate transaction tab event caught');
        console.log(jsObj.jobid);
        this.activeTabValue = jsObj.tabname;
        if(this.progressBarValue === 100){
            console.log('Progress bar value 100');
            console.log(this.progressBarValue);
            clearInterval(this._interval);
        }else{
            //need to increment progress bar value
            console.log('Inside else');
            //call the apex funtion withing interval 
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            this._interval = setInterval(() => {
                //this.progressBarValue = this.progressBarValue === 100 ? 100 : this.progressBarValue + 1;
                //console.log('inside set interval');
                console.log(this.progressBarValue);
                if(this.progressBarValue === 100){
                    //console.log('Inside 100 %%');
                    clearInterval(this._interval);
                }else{
                    getMigrateBatchStatus({batchJobId : jsObj.jobid})
                    .then(result =>{
                        //console.log('Success get migratebatchstatus');
                        //console.log(result);
                        let batchJob = result;
                        let per = (batchJob.JobItemsProcessed/batchJob.TotalJobItems)*100;
                        this.jobItemsProcessed = batchJob.JobItemsProcessed;
                        this.totalJobItems = batchJob.TotalJobItems;
                        this.jobStatus = batchJob.Status;
                        this.progressBarValue = per;
                        if(per === 100){
                            this.progressText  = 'Completed';
                            this.getBatchTransactionalDetails(jsObj.jobid);
                            //this.getBatchTransactionalDetails();
                        }
                    })
                    .catch(error =>{
                        console.log('Error in get MigrateBatchStatus');
                        console.log(error);
                    })
                }
            },1000);
            
        }

    }
    
    getBatchTransactionalDetails(jobid){
        console.log('Inside getBatchTransactionalDetails after batch execution');
        console.log(jobid);
        getBatchTransactionalDetails({batchId : jobid})
        .then(result =>{
            console.log(result);
            this.objectName = result.Object_setup_name__r.Name;
            this.jobItemsProcessedDetail = result.Batch_Success__c;
            this.totalJobItemsDetail = result.Total_Batch__c ;
            this.failedJobitemsDetail =result.Batch_Failed__c ;
            this.salesforceOrgName =result.Object_setup_name__r.SalesforceOrg__r.Name;

        })
        .catch(error =>{
            console.log('Inside getBatchTransactionalDetails');
            console.log(error);        
        })
    }

}