package symbolTable.types;

import errorHandling.ErrorMessage;
import java.util.ArrayList;
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
            isAbstract;
    
    
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
    public Method(Type returnValue, ArrayList<Type> parameters, boolean isVirtual, boolean isAbstract, boolean isConst){
        this.s = new Signature(returnValue, parameters);
        this.isVirtual = isVirtual;
        this.isAbstract = isAbstract;
        this.isConst = isConst;
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
            if(this.s.equals(m.s) == false) return false;
            if(this.s.returnValue.equals(m.s.returnValue) == false) return false;
            if(this.isAbstract != m.isAbstract) return false;
            if(this.isVirtual != m.isVirtual) return false;
            if(this.isConst != m.isConst) return false;
            return true;
        }
        return false;
    }
    
    /**
     * Sets the type that the method belongs to. If the method is in global scope
     * this method is not being invoked.
     * 
     * @param t The UserDefinedType class that represents method's type.
     */
    public void setNamespace(DefinesNamespace t){
        this.belongsTo = t;
    }
    
    @Override
    protected StringBuilder getString(StringBuilder aggr) {
        aggr.append(s.returnValue);
        aggr.append("(");
        int size = s.parameters.size();
        for(int i = 0 ; i < size ; ++i){
            Type t = s.parameters.get(i);
            aggr.append(i == 0 ? "" : ",");
            aggr.append(t);
        }
        aggr.append(")");
        return aggr;
    }
    
    public Type getReturnType(){
        return s.returnValue;
    }
    
    public Signature getSignature(){
        return this.s;
    }
    
    public boolean isVirtual(){
        return isVirtual;
    }
    
    public void setVirtual(){
        isVirtual = true;
    }

    @Override
    public int hashCode() {
        int hash = 7;
        hash = 17 * hash + (this.s != null ? this.s.hashCode() : 0);
        return hash;
    }
    
    public boolean isOverriderFor(Method m) throws ErrorMessage{
        boolean subtype = this.s.returnValue.subType(m.s.returnValue);
        return subtype;
    }
    
}
