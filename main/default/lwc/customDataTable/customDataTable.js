import LightningDatatable from 'lightning/datatable';
import ProductQuantityRenderer from './productQuantityRenderer.html';

export default class CustomDataTable extends LightningDatatable {
    static customTypes = {
        productQuantity: {  // type of custom element
            template: ProductQuantityRenderer, // Which html will render
            typeAttributes: ['quantity', 'truckVIN'],  // attribute of custom type
        }
    };
}