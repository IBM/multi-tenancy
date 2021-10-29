package com.ibm.catalog;

import javax.persistence.*;

@Entity
@Table(name = "productcategory")
@NamedQuery(name = "ProductCategory.findByCategoryId", query = "SELECT f FROM ProductCategory f WHERE f.categoryid=:categoryid")
public class ProductCategory {

    @Id
    @SequenceGenerator(name = "productcategorySequence", sequenceName = "productcategory_id_seq", allocationSize = 1, initialValue = 10)
    @GeneratedValue(generator = "productcategorySequence")
    private Integer id;

    @Column
    private Integer productid;

    @Column
    private Integer categoryid;

    public ProductCategory() {
    }

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }


    public Integer getProductid() {
        return productid;
    }

    public void setProductid(Integer productid) {
        this.productid = productid;
    }

    public Integer getCategoryid() {
        return categoryid;
    }

    public void setCategoryid(Integer categoryid) {
        this.categoryid = categoryid;
    }
}
