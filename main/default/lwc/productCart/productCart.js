import { LightningElement, wire, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { MessageContext, subscribe, unsubscribe, APPLICATION_SCOPE } from 'lightning/messageService';
import DragDropChannel from "@salesforce/messageChannel/dragAndDropChannel__c";
import CustomTableChannel from "@salesforce/messageChannel/customTableChannel__c";

/*Apex Controller Methods*/
import createOppProducts from '@salesforce/apex/AddProductsContainerController.createOppProducts';
import getOppLineItems from '@salesforce/apex/AddProductsContainerController.getOppLineItems';
import incrementOppLineItems from '@salesforce/apex/AddProductsContainerController.incrementOppLineItems';
import deleteOppLineItems from '@salesforce/apex/AddProductsContainerController.deleteOppLineItems';

/*Schema Fields*/
import AMOUNT_FIELD from '@salesforce/schema/Opportunity.Amount';
import CURRENCY_FIELD from '@salesforce/schema/Opportunity.CurrencyIsoCode';

export default class ProductCart extends LightningElement {
    @api oppId;
    @api productList;

    isLoaded = true;
    refreshProductList;
    draggedProduct;
    subscriptionDragDropChannel = null;
    subscriptionCustomTableChannel = null;

    sortBy;
    sortDirection = 'asc';

    columns = [ {label: 'Name', fieldName: 'truckName', type: 'text' ,sortable:true, wrapText: true},
                {label: 'Quantity', type: 'productQuantity' , 
                    typeAttributes:{
                        quantity: {fieldName : 'truckQty'}, 
                        truckVIN: {fieldName : 'truckVIN'}
                    }
                },
                {label: 'Price', fieldName: 'truckLinePrice', type: 'currency' ,sortable:true, wrapText: true, 
                    typeAttributes: { 
                        currencyCode: 'USD'
                    }
                },
                {label: 'Actions', type : 'button-icon', 
                    typeAttributes: { 
                        name: 'delete', 
                        iconName: 'utility:delete', 
                        size: 'x-small'}}];

    /*Wire Methods*/

    @wire(MessageContext)
    messageContext;

    @wire(getOppLineItems, { opportunityId: '$oppId' })
    wiredOppLineData(result) {
        this.refreshProductList = result;
        if (result.data) {
            this.productList = result.data;
        } else if (result.error) {
            console.error(error);
        }
    }

    @wire(getRecord, { recordId: '$oppId', fields: [AMOUNT_FIELD, CURRENCY_FIELD] })
    opportunity;

    /*Getter Methods*/

     get totalAmount() {
        let calculatedValue = '0';
        let amountValue = getFieldValue(this.opportunity.data, AMOUNT_FIELD);
        let currencyCode = getFieldValue(this.opportunity.data, CURRENCY_FIELD);
        calculatedValue = amountValue.toLocaleString() + ' ' + currencyCode;
        return calculatedValue;
    }

    /*Generic Methods*/

    allowDrop(event){
        event.preventDefault();
    }

    drop(event){
        event.preventDefault();
        //Remove glow on Container
        this.template.querySelector('.productsContainer').classList.remove('glow');
        this.isLoaded = false;
        try {
            let prodList = this.productList ? JSON.parse(JSON.stringify(this.productList)) : undefined;

            //CREATING PROD
            if (!prodList || (!prodList.some(e => e.truckVIN === this.draggedProduct.truckVIN))) {
                //Initialize Line Prices & Push Product to List
                let initializeProd = this.initializeProdPrice(this.draggedProduct);
                let newProdArray = [initializeProd];

                //Try to insert Products as Opportunity Line Items
                let updateTable = Promise.resolve(this.insertOppLineItems(newProdArray,this.oppId)).then(function(result) {
                    this.isLoaded = true;
                    //If success, update productList on front-end
                    if (result) {
                        refreshApex(this.refreshProductList);
                        getRecordNotifyChange([{recordId: this.oppId}]);
                    }
                }.bind(this));

            //increase the quantity
            } else {
                let quantity;
                let oppLineItemId;
                let unitPrice;
                prodList.forEach(element => {
                    if (element.truckVIN == this.draggedProduct.truckVIN) {
                        quantity = element.truckQty + 1;
                        oppLineItemId = element.oppLineItemId;
                        unitPrice = element.truckPrice;
                    }
                });

                //Try to insert Products as Opportunity Line Items
                let updateLineItem = Promise.resolve(this.incrementOppLineItem(oppLineItemId, quantity, unitPrice)).then(function(value) {    
                    this.isLoaded = true;
                    //If success, update productList on front-end
                    if (value) {
                        refreshApex(this.refreshProductList);
                        getRecordNotifyChange([{recordId: this.oppId}]);
                    }
                }.bind(this));
                
            }
        } catch(error) {
            console.error(error);
        }
    }

    //Initialize Product List Price if added through Layout
    initializeProdPrice(product) {
        let initProduct = JSON.parse(JSON.stringify(product));
        if (initProduct && !initProduct.truckLinePrice) {
            initProduct['truckLinePrice'] = initProduct.truckQty * initProduct.truckPrice;
        }

        return initProduct;
    }

    subscribeToDragDropChannel() {
        if (!this.subscriptionDragDropChannel) {
            this.subscriptionDragDropChannel = subscribe(
                this.messageContext,
                DragDropChannel,
                (message) => this.handleMessageDragDropChannel(message),
                { scope: APPLICATION_SCOPE }
            );
        }
    }

    unsubscribeToDragDropChannel() {
        unsubscribe(this.subscriptionDragDropChannel);
        this.subscriptionDragDropChannel = null;
    }

    // Handler for message received by component
    handleMessageDragDropChannel(message) {
        //Set glow on Container
        this.template.querySelector('.productsContainer').classList.add('glow');
        //Set Data
        if(message.truckData) {
            this.draggedProduct = message.truckData;
        }
    }

    subscribeToCustomTableChannel() {
        if (!this.subscriptionCustomTableChannel) {
            this.subscriptionCustomTableChannel = subscribe(
                this.messageContext,
                CustomTableChannel,
                (message) => this.handleMessageCustomTableChannel(message),
                { scope: APPLICATION_SCOPE }
            );
        }
    }

    unsubscribeToCustomTableChannel() {
        unsubscribe(this.subscriptionCustomTableChannel);
        this.subscriptionCustomTableChannel = null;
    }

    // Handler for message received by component
    handleMessageCustomTableChannel(message) {
        this.isLoaded = false;
        if(message.truckVIN && message.quantity) {
            let prodList = JSON.parse(JSON.stringify(this.productList));
            let quantity;
            let oppLineItemId;
            let unitPrice;
                    
            prodList.forEach(element => {
                if (element.truckVIN == this.draggedProduct.truckVIN) {
                    quantity = element.truckQty + message.quantity;
                    oppLineItemId = element.oppLineItemId;
                    unitPrice = element.truckPrice;
                }
            });

            //Try to insert Products as Opportunity Line Items
            let updateLineItem = Promise.resolve(this.incrementOppLineItem(oppLineItemId, quantity, unitPrice)).then(function(value) {    
                this.isLoaded = true;
                //If success, update productList on front-end
                if (value) {
                    refreshApex(this.refreshProductList);
                    getRecordNotifyChange([{recordId: this.oppId}]);
                }
            }.bind(this));
        }
    }

    handleRowAction(event) {
        if (event.detail.action.name === 'delete') {
            this.isLoaded = false;
            let prod = event.detail.row;

            let deleteLineItem = Promise.resolve(this.deleteLineItem(prod.oppLineItemId)).then(function(value) {    
                this.isLoaded = true;
                //If success, update productList on front-end
                if (value) {
                    refreshApex(this.refreshProductList);
                    getRecordNotifyChange([{recordId: this.oppId}]);
                }
            }.bind(this));
            
        }
    }

    removeFromArray(productVIN, productList) {
        var removeIndex = productList.map(item => item.truckVIN).indexOf(productVIN);
        ~removeIndex && productList.splice(removeIndex, 1);
        return productList;
    }

    sortColumns (event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
    }

    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.productList));
        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };
        // cheking reverse direction
        let isReverse = direction === 'asc' ? 1: -1;
        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';
            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });
        this.productList = parseData;
    }

    /*Async Methods*/
    async insertOppLineItems(truckList, opportunityId) {
        let isSuccess = false;
        await createOppProducts({truckWrapperList : truckList, opportunityId : opportunityId})
            .then(result => {
                isSuccess = result;
                return isSuccess;
            })
            .catch(error => {
                console.error(error);
            });

        return isSuccess;
    }

    async incrementOppLineItem(oppLineItemId, quantity, unitPrice) {
        let isSuccess = false;
        await incrementOppLineItems({oppLineItemId : oppLineItemId, qty : quantity, unitPrice : unitPrice})
            .then(result => {
                isSuccess = result;
                return isSuccess;
            })
            .catch(error => {
                console.error(error);
            });

        return isSuccess;
    }

    async deleteLineItem(oppLineItemId) {
        let isSuccess = false;
        await deleteOppLineItems({oppLineItemId : oppLineItemId})
            .then(result => {
                isSuccess = result;
                return isSuccess;
            })
            .catch(error => {
                console.error(error);
            });

        return isSuccess;
    }

    /*Life Cycle Hooks*/
    // Standard lifecycle hooks used to subscribe and unsubsubscribe to the message channel
    connectedCallback() {
        this.subscribeToDragDropChannel();
        this.subscribeToCustomTableChannel();
    }

    disconnectedCallback() {
        this.unsubscribeToDragDropChannel();
        this.unsubscribeToCustomTableChannel();
    }
}