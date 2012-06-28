package symbolTable.types;

/**
 *
 * @author kostas
 */
public abstract class Type {
    
    protected abstract StringBuilder getString(StringBuilder aggr);
    
    public abstract boolean subType(Type lhs);
    
    @Override
    public String toString(){
        StringBuilder rv = new StringBuilder();
        return this.getString(rv).toString();
    }
    
//    public String getType(){
//        StringBuilder rv = new StringBuilder();
//        return this.findType(rv).toString();
//    }
    
//    @Override
//    public boolean equals(Object t){
//        if(t instanceof Type){
//            Type t1 = (Type)t;
//            return this.getType().equals(t1.getType());
//        }
//        else{
//            return false;
//        }
//    }

//    @Override
//    public int hashCode() {
//        int hash = 7;
//        return hash;
//    }
    
}
