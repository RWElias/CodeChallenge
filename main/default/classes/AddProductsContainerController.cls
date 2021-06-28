public without sharing class AddProductsContainerController {
    
    @AuraEnabled(cacheable=true)
    public static List<AddProductsControllerHelper.TruckWrapper> getProducts(Id opportunityId){
        try {
            return AddProductsControllerHelper.getProducts(opportunityId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<AddProductsControllerHelper.TruckWrapper> getOppLineItems(Id opportunityId){
        try {
            return AddProductsControllerHelper.getOppLineItems(opportunityId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean createOppProducts(List<AddProductsControllerHelper.TruckWrapper> truckWrapperList, Id opportunityId){
        try {
            return AddProductsControllerHelper.createOppProducts(truckWrapperList, opportunityId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean incrementOppLineItems(Id oppLineItemId, Integer qty, Decimal unitPrice){
        try {
            return AddProductsControllerHelper.incrementOppLineItems(oppLineItemId, qty, unitPrice);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean deleteOppLineItems(Id oppLineItemId){
        try {
            return AddProductsControllerHelper.deleteOppLineItems(oppLineItemId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}