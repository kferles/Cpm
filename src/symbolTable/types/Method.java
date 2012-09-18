package symbolTable.types;

import errorHandling.AmbiguousBaseClass;
import java.util.ArrayList;
import symbolTable.namespace.CpmClass;
import symbolTable.namespace.DefinesNamespace;

/**
 *
 * @author kostas
 */
public class Method extends Type{

    @Override
    public boolean subType(Type o) {
        return this.equals(o);
    }
    
    /**
     * Auxiliary class describing the signature of a method.
     * Contains the return value and a list with the parameters.
     */
    public class Signature{

        Type returnValue;

        ArrayList<Type> parameters;

        /**
            * Constructs a signature given the return value and a list with the parameters.
            * 
            * @param returnValue   A reference to the object that describes the of of the return value.
            * @param parameters    A list with objects that describe each parameter 's type.
            */
        public Signature(Type returnValue, ArrayList<Type> parameters){
            this.returnValue = returnValue;
            this.parameters = parameters;
        }
        
        public Type getReturnValue(){
            return this.returnValue;
        }
        
        public ArrayList<Type> getParameters(){
            return this.parameters;
        }
        
        public void setReturnValue(Type t){
            this.returnValue = t;
        }
        
        public void setParameters(ArrayList<Type> params){
            this.parameters = params;
        }

        @Override
        public boolean equals(Object o){
            if(o instanceof Signature){
                Signature s1 = (Signature)o;
               //if(this.returnValue.equals(s1.returnValue) == false) return false;
                if((this.parameters == null && s1.parameters != null)
                    ||
                    (this.parameters != null && s1.parameters == null)) return false;
                if(this.parameters != null && s1.parameters != null){
                    int size1 = this.parameters.size(), size2 = s1.parameters.size();
                    if(size1 != size2) return false;
                    for(int i = 0 ; i < size1 ; ++i)
                        if(this.parameters.get(i).equals(s1.parameters.get(i)) == false) return false;
                }
                return true;
            }
            return false;
        }

        @Override
        public int hashCode() {
            int hash = 5;
            hash = 97 * hash + (this.parameters != null ? this.parameters.hashCode() : 0);
            return hash;
        }
    }
    
    Signature s;
    
    boolean isVirtual,
            isAbstract,
            isExplicit = false;
    
    
    /*
     * probably out of here. 
     */
    DefinesNamespace belongsTo = null;
    
    /**
     * Constructs a Method object given the type of the return value and
     * the types of its parameters. If method has some modifiers the appropriate
     * boolean parameter should be true.
     * 
     * @param returnValue   The type of the return value.
     * @param parameters    An array list containing the types of all parameters.
     * @param isVirtual     Whether method is virtual or not.
     * @param isAbstract    Whether method is implemented or not.
     * @param isConst       Whether method is const or not.
     */
    public Method(Type returnValue, ArrayList<Type> parameters, DefinesNamespace belongsTo, 
                  boolean isVirtual, boolean isAbstract, boolean isConst, boolean isVolatile){
        this.s = new Signature(returnValue, parameters);
        this.isVirtual = isVirtual;
        this.isAbstract = isAbstract;
        this.isConst = isConst;
        this.isVolatile  = isVolatile;
        this.belongsTo = belongsTo;
    }
    
    /**
     * In case the argument is also an instance of Method class
     * equals returns true if the signatures are also equals and false otherwise.
     * On the other hand if the parameter is not instance of class Method it returns false.
     * @param o The object to check for equality.
     * @return  True if methods have the same type and false otherwise.
     */
    @Override
    public boolean equals(Object o){
        if(o == null) return false;
        if(o instanceof Method){
            Method m = (Method)o;
            if(this.belongsTo != m.belongsTo) return false;
            if(this.s.equals(m.s) == false) return false;
            if(this.s.returnValue.equals(m.s.returnValue) == false) return false;
            if(this.isAbstract != m.isAbstract) return false;
            if(this.isVirtual != m.isVirtual) return false;
            if(this.isConst != m.isConst) return false;
            if(this.isVolatile != m.isVolatile) return false;
            return true;
        }
        return false;
    }

    @Override
    public int hashCode() {
        int hash = 3;
        hash = 67 * hash + (this.s != null ? this.s.hashCode() : 0);
        hash = 67 * hash + (this.isVirtual ? 1 : 0);
        hash = 67 * hash + (this.isAbstract ? 1 : 0);
        hash = 67 * hash + (this.belongsTo != null ? this.belongsTo.hashCode() : 0);
        return hash;
    }
    
    @Override
    protected StringBuilder getString(StringBuilder aggr) {
        StringBuilder virt = null;
        if(this.isVirtual == true) virt = new StringBuilder("virtual ");
        StringBuilder start = new StringBuilder(s.returnValue != null ? s.returnValue.toString() : "");
        int rParenIndex = start.indexOf(")");
        String end = null;
        if(rParenIndex != -1){
            end = start.substring(rParenIndex, start.length());
            start = new StringBuilder(start.substring(0, rParenIndex));
        }
        String namespace = this.belongsTo.getName();
        start.append(" ");
        start.append(aggr);
        aggr = start.append("(");
        if(s.parameters != null){
            int size = s.parameters.size();
            for(int i = 0 ; i < size ; ++i){
                Type t = s.parameters.get(i);
                aggr.append(i == 0 ? "" : ",");
                aggr.append(t);
            }
        }
        aggr.append(")");
        if(this.isConst == true) aggr.append(" const");
        if(this.isVolatile == true) aggr.append(" volatile");
        if(end != null) aggr.append(end);
        if(virt == null){
            return aggr;
        }
        else{
            return virt.append(aggr);
        }
    }
    
    @Override
    public String toString(String id){
        return this.getString(new StringBuilder(id)).toString();
    }
    
    public Type getReturnType(){
        return s.returnValue;
    }
    
    public Signature getSignature(){
        return this.s;
    }
    
    public DefinesNamespace getParent(){
        return this.belongsTo;
    }
    
    public boolean isVirtual(){
        return this.isVirtual;
    }
    
    public void setVirtual(boolean isVirtual){
        this.isVirtual = isVirtual;
    }
    
    public void setExplicit(){
        this.isExplicit = true;
    }
    
    public boolean isExplicit(){
        return this.isExplicit;
    }
    
    public boolean isOverriderFor(Method m) throws AmbiguousBaseClass{
        return this.s.returnValue.subType(m.s.returnValue);
    }
    
    @Override
    public boolean isComplete(CpmClass _){
        return true;
    }
    
}
