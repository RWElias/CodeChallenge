import { LightningElement, api, wire } from 'lwc';
import { MessageContext, publish } from 'lightning/messageService';
import  CustomTableChannel from "@salesforce/messageChannel/customTableChannel__c";

export default class ProductQuantity extends LightningElement {
    @api productQty;
    @api truckVIN;

    @wire(MessageContext)
    messageContext;

    onQuantityChange(event) {
        let quantity = event.target.value - this.productQty;

        //Validate if its 0 or below
        if (event.target.value <= 0) {
            quantity = 0;
        }

        //Validate if there are decimal numbers in Quantity
        if (event.target.value % 1 != 0) {
            this.template.querySelector('.quantity-input').classList.add('invalid-input');
        } else {
            this.template.querySelector('.quantity-input').classList.remove('invalid-input');

            
            //Prepare data to send to subscribers
            const message = {
                quantity: quantity,
                truckVIN: this.truckVIN
            };
            publish(this.messageContext, CustomTableChannel, message);
        }
    }
}