public without sharing class AddProductsControllerHelper {
    
    /*Controller Methods*/
    /*
        TODO: make API call with VIN number, if there is no value for vehicle, use Prod default
    */
    public static List<TruckWrapper> getProducts(Id opportunityId) {
        List<Product2> productList = new List<Product2>();
        List<TruckWrapper> truckWrapperList = new List<TruckWrapper>();

        //If Opportunity Id is empty we return 
        if (String.isBlank(opportunityId)) {
            return truckWrapperList;
        }

        //Retrieve the Pricebook Id related to the current Opportunity
        Id priceBookId = [SELECT Pricebook2Id FROM Opportunity WHERE Id =: opportunityId]?.Pricebook2Id;
        

        if (String.isNotBlank(priceBookId)) {
            //Query Products related to the correct Pricebook Id
            productList = [SELECT Id, Name, lt_Horse_Power__c, lt_Make__c, lt_Model__c, lt_VIN__c, lt_Weight__c,
                                (SELECT Id, UnitPrice FROM PricebookEntries WHERE Pricebook2Id =: priceBookId LIMIT 1)
                            FROM Product2 
                            WHERE Family =: LT_Constants.PRODUCT_FAMILY_TRUCK 
                            AND Id IN (SELECT Product2Id FROM PricebookEntry WHERE Pricebook2Id =: priceBookId)];

            //Convert to TruckWrapper
            for (Product2 prod : productList) {
                truckWrapperList.add(new TruckWrapper(prod));
            }
        }

        return truckWrapperList;
    }

    public static List<TruckWrapper> getOppLineItems(Id opportunityId) {
        List<OpportunityLineItem> lineItems = new List<OpportunityLineItem>();
        List<TruckWrapper> truckWrapperList = new List<TruckWrapper>();

        //If Opportunity Id is empty we return 
        if (String.isBlank(opportunityId)) {
            return truckWrapperList;
        }
        //Query Products related to the correct OpportunityId
        lineItems = [SELECT Id, Quantity, TotalPrice, UnitPrice, PricebookEntryId, 
                            Product2.Name, Product2.lt_Make__c, Product2.lt_Model__c, 
                            Product2.lt_VIN__c, Product2.lt_Weight__c, Product2.lt_Horse_Power__c 
                    FROM OpportunityLineItem 
                    WHERE OpportunityId =: opportunityId];

        //Convert to TruckWrapper
        for (OpportunityLineItem lineItem : lineItems) {
            truckWrapperList.add(new TruckWrapper(lineItem));
        }

        return truckWrapperList;
    }

    public static Boolean incrementOppLineItems(Id oppLineItemId, Integer qty, Decimal unitPrice) {
        Boolean isSuccess = false;
        if (String.isNotBlank(oppLineItemId) && qty != null) {
            OpportunityLineItem lineItemToUpdate = new OpportunityLineItem(Id = oppLineItemId);
            lineItemToUpdate.quantity = qty;
            lineItemToUpdate.TotalPrice = qty * unitPrice;

            Database.SaveResult updateResult = Database.update(lineItemToUpdate, true);
            isSuccess = validateSaveResults(new List<Database.SaveResult> {updateResult});
        }

        return isSuccess;
    }

    public static Boolean deleteOppLineItems(Id oppLineItemId) {
        Boolean isSuccess = false;
        if (String.isNotBlank(oppLineItemId)) {
            OpportunityLineItem lineItemToDelete = new OpportunityLineItem(Id = oppLineItemId);

            Database.DeleteResult deleteResult = Database.delete(lineItemToDelete, true);
            isSuccess = validateDeleteResults(new List<Database.DeleteResult> {deleteResult});
        }

        return isSuccess;
    }

    public static Boolean createOppProducts(List<TruckWrapper> truckWrapperList, Id opportunityId) {
        List<OpportunityLineItem> lineItemsToInsert = new List<OpportunityLineItem>();
        Boolean isSuccess = false;

        for (TruckWrapper truckRecord : truckWrapperList) {
            lineItemsToInsert.add(mapWrappertoOppLineItem(truckRecord, opportunityId));
        }

        if (!lineItemsToInsert.isEmpty()) {
            List<Database.SaveResult> insertResults = Database.insert(lineItemsToInsert, false);
            isSuccess = validateSaveResults(insertResults);
        }
        return isSuccess;
    }

    /*Private Methods*/

    private static OpportunityLineItem mapWrappertoOppLineItem(TruckWrapper truckRecord, Id opportunityId) {
        OpportunityLineItem lineItem = new OpportunityLineItem();
        lineItem.OpportunityId = opportunityId;
        lineItem.PricebookEntryId = truckRecord.priceBookEntryId;
        lineItem.Product2Id = truckRecord.productId;
        lineItem.Quantity = truckRecord.truckQty;
        lineItem.TotalPrice = truckRecord.truckLinePrice;
        return lineItem;
    }

    private static Boolean validateSaveResults(List<Database.SaveResult> results) {
        Boolean isSuccess = true;

        for (Database.SaveResult result : results) {
            if (!result.isSuccess()) {
                isSuccess = false;
                break;
            }
        }
        return isSuccess;
    }

    private static Boolean validateDeleteResults(List<Database.DeleteResult> results) {
        Boolean isSuccess = true;

        for (Database.DeleteResult result : results) {
            if (!result.isSuccess()) {
                isSuccess = false;
                break;
            }
        }
        return isSuccess;
    }

    /*Wrapper Classes*/

    public class TruckWrapper {
        @AuraEnabled
        public String truckName {get; set;}
        @AuraEnabled
        public String truckMake {get; set;}
        @AuraEnabled
        public String truckModel {get; set;}
        @AuraEnabled
        public String truckVIN {get; set;}
        @AuraEnabled
        public Decimal truckWeight {get; set;}
        @AuraEnabled
        public Decimal truckHorsePower {get; set;}
        @AuraEnabled
        public Decimal truckPrice {get; set;}
        @AuraEnabled
        public Decimal truckLinePrice {get; set;}
        @AuraEnabled
        public Integer truckQty {get; set;}
        @AuraEnabled
        public String priceBookEntryId {get; set;}
        @AuraEnabled
        public String productId {get; set;}
        @AuraEnabled
        public String oppLineItemId {get; set;}

        public TruckWrapper () {}

        public TruckWrapper (Product2 prod) {
            this.truckName          = String.isNotBlank(prod.Name)              ? prod.Name                 : LT_Constants.NO_DATA;
            this.truckMake          = String.isNotBlank(prod.lt_Make__c)        ? prod.lt_Make__c           : LT_Constants.NO_DATA;
            this.truckModel         = String.isNotBlank(prod.lt_Model__c)       ? prod.lt_Model__c          : LT_Constants.NO_DATA;
            this.truckVIN           = String.isNotBlank(prod.lt_VIN__c)         ? prod.lt_VIN__c            : LT_Constants.NO_DATA;
            this.truckWeight        = prod.lt_Weight__c != null                 ? prod.lt_Weight__c         : 0;
            this.truckHorsePower    = prod.lt_Horse_Power__c != null            ? prod.lt_Horse_Power__c    : 0;
            this.truckQty           = 1;
            this.productId          = prod.Id;

            if (!prod.PricebookEntries.isEmpty()) {
                this.truckPrice = prod.PricebookEntries.get(0).UnitPrice;
                this.priceBookEntryId = prod.PricebookEntries.get(0).Id;
            } else {
                this.truckPrice = 0;
            }
        }

        public TruckWrapper (OpportunityLineItem lineItem) {
            this.truckName          = String.isNotBlank(lineItem.Product2.Name)             ? lineItem.Product2.Name                : LT_Constants.NO_DATA;
            this.truckMake          = String.isNotBlank(lineItem.Product2.lt_Make__c)       ? lineItem.Product2.lt_Make__c          : LT_Constants.NO_DATA;
            this.truckModel         = String.isNotBlank(lineItem.Product2.lt_Model__c)      ? lineItem.Product2.lt_Model__c         : LT_Constants.NO_DATA;
            this.truckVIN           = String.isNotBlank(lineItem.Product2.lt_VIN__c)        ? lineItem.Product2.lt_VIN__c           : LT_Constants.NO_DATA;
            this.truckWeight        = lineItem.Product2.lt_Weight__c != null                ? lineItem.Product2.lt_Weight__c        : 0;
            this.truckHorsePower    = lineItem.Product2.lt_Horse_Power__c != null           ? lineItem.Product2.lt_Horse_Power__c   : 0;
            this.truckQty           = lineItem.Quantity != null                             ? Integer.valueOf(lineItem.Quantity)    : 0;
            this.productId          = String.isNotBlank(lineItem.Product2Id)                ? lineItem.Product2Id                   : LT_Constants.NO_DATA;
            this.truckPrice         = lineItem.UnitPrice != null                            ? lineItem.UnitPrice                    : 0;
            this.priceBookEntryId   = String.isNotBlank(lineItem.PricebookEntryId)          ? lineItem.PricebookEntryId             : LT_Constants.NO_DATA;
            this.truckLinePrice     = lineItem.TotalPrice != null                           ? lineItem.TotalPrice                   : 0;
            this.oppLineItemId      = String.isNotBlank(lineItem.Id)                        ? lineItem.Id                           : LT_Constants.NO_DATA;
        }
        
    }
}