import { LightningElement, api, wire } from 'lwc';
import { MessageContext, publish } from 'lightning/messageService';
import DragDropChannel from "@salesforce/messageChannel/dragAndDropChannel__c";

export default class ProductTile extends LightningElement {
    @api product;
    @api productVIN;

    @wire(MessageContext)
    messageContext;

    drag(event) {
        const message = {
            truckData: this.product,
            truckVin: this.productVIN
        };
        publish(this.messageContext, DragDropChannel, message);
    }
}