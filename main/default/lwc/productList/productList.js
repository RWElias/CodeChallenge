import { LightningElement, api, wire } from 'lwc';
import getProducts from '@salesforce/apex/AddProductsContainerController.getProducts';

export default class ProductList extends LightningElement {
    @api oppId;
    @api productList;

    @wire(getProducts, { opportunityId: '$oppId' })
    wiredProdData({ data, error }) {
        if (data) {
            this.productList = data;
        } else if (error) {
            console.error(error);
        }
    }
}