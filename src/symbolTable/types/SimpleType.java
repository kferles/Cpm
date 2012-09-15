package symbolTable.types;

/**
 *
 * @author kostas
 */
public abstract class SimpleType extends Type {
    
    String name;
    
    public SimpleType(String name){
        this.name = name;
    }
    
    @Override
    public boolean equals(Object o){
        if(o == null) return false;
        if(o instanceof SimpleType){
            if(super.equals(o) == false) return false;
            SimpleType st = (SimpleType) o;
            return this.name.equals(st.name);
        }
        return false;
    }
    
    @Override
    protected StringBuilder getString(StringBuilder aggr){
        StringBuilder n = new StringBuilder(this.isConst == true ? "const " : "");
        n.append(this.isVolatile == true ? "volatile " : "");
        n.append(this.name);
        n.append(aggr.toString().equals("") ? "" : " ");
        return n.append(aggr);
    }
    
    @Override
    public String toString(String id){
        return this.getString(new StringBuilder(id)).toString();
    }

    @Override
    public int hashCode() {
        int hash = 7;
        hash = 53 * hash + (this.name != null ? this.name.hashCode() : 0);
        return hash;
    }

}
