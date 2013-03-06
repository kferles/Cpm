package symbolTable.types;

import errorHandling.VoidDeclaration;
import symbolTable.namespace.CpmClass;
import symbolTable.namespace.TypeDefinition;
import symbolTable.namespace.SynonymType;


/**
 *
 * @author kostas
 */
public class PrimitiveType extends SimpleType {
    
//    private static String types[] = {"bool", 
//                                     "char", "unsigned char",
//                                     "short", "unsigned short", 
//                                     "int", "unsigned int", 
//                                     "long", "unsigned long", 
//                                     "long long", "unsigned long long",
//                                     "float", "double", "long double"};
    
    private static String void_t[] = {"void"};
    
    private static String bool[] = {"bool"};
    
    private static String signedInts[] = {"char", "short", "int", "long", "long long"};
    
    private static String unsignedInts[] = {"unsigned char", "unsigned short", 
                                            "unsigned int", "unsigned long",
                                            "unsigned long long"};
    
    private static String doubles[] = {"float", "double", "long double"};
    
    private String _type[] = null;
    
    private int index = -1;
    
    private void searchInArray(String ar[]){
        for(int i = 0 ; i < ar.length ; ++i){
            String s = ar[i];
            if(name.equals(s)){
                this._type = ar;
                this.index = i;
                return;
            }
        }
    }
    
    public PrimitiveType(String name, boolean isConst, boolean isVolatile){
        super(name);
        this.isConst = isConst;
        this.isVolatile = isVolatile;
        switch (name) {
            case "short int":
                name = "short";
                break;
            case "long int":
                name = "long";
                break;
            case "long long int":
                name = "long long";
                break;
            case "unsigned short int":
                name = "unsigned short";
                break;
            case "unsigned long int":
                name = "unsigned long";
                break;
            case "unsigned long long int":
                name = "unsigned long long";
                break;
        }
        this.name = name;
        if(name.equals("bool") == true){
            this._type = PrimitiveType.bool;
            this.index = 0;
        }
        else if(name.equals("void") == true){
            this._type = PrimitiveType.void_t;
            this.index = 0;
        }
        else{
            searchInArray(PrimitiveType.signedInts);
            if(this._type != null && this.index != -1) return;
            searchInArray(PrimitiveType.unsignedInts);
            if(this._type != null && this.index != -1) return;
            searchInArray(PrimitiveType.doubles);
            //if(this._type != null && this.index != -1) return;
            //if i cannot ensure form antlr that the name would be valid throw an exception here.
        }
    }

    @Override
    public boolean subType(Type o){
        return this.equals(o);
    }
    
    @Override
    public boolean isComplete(CpmClass _) throws VoidDeclaration{
        if(this._type == PrimitiveType.void_t && this.index == 0){
            throw new VoidDeclaration();
        }
        return true;
    }
    
    @Override
    public boolean isOverloadableWith(Type o, boolean isPointer){
        if(o instanceof PrimitiveType){ 
            PrimitiveType pt = (PrimitiveType)o;
            if(isPointer == true){
                if(this.isConst != pt.isConst) return true;
                if(this.isVolatile != pt.isVolatile) return true;
            }
            if(this._type == pt._type && this.index == pt.index) return false;
        }
        else if(o instanceof UserDefinedType){
            UserDefinedType u_t = (UserDefinedType)o;
            return u_t.isOverloadableWith(this, isPointer);
        }
        return true;
    }
    
    @Override
    public boolean isOverloadableWith(TypeDefinition o, boolean isPointer){
        if(o instanceof CpmClass){
            return true;
        }
        else{
            SynonymType s_t = (SynonymType)o;
            if(s_t.getTag().equals("typedef") == true){
                return this.isOverloadableWith(s_t.getSynonym(), isPointer);
            }
            return true;
        }
    }
    
    @Override
    public int overloadHashCode(boolean isPointer){
        int hash = 13;
        if(isPointer == true){
            hash = hash * 151 + (this.isConst ? 1 : 0);
            hash = hash * 151 + (this.isVolatile ? 1 : 0);
        }
        return hash + this.name.hashCode();
    }
    

//      this one when this can be assigned to an other type   
//    {
//        if(o == null) return false;
//        if(o instanceof PrimitiveType){
//            PrimitiveType p = (PrimitiveType) o;
//            /*
//             * according to Cpm design conversion from a const to a non const type is not allowed.
//             */
//            if(super.isConst == true && p.isConst == false) return false;
//            /*
//             * subtyping for integer like types according to Cpm design.
//             */
//            if(this._type == p._type && this.index <= p.index) return true;
//            if(this._type == PrimitiveType.signedInts && p._type == PrimitiveType.doubles){
//                if(this.name.equals("long long") && !p.name.equals("long double")) return false;
//                return true;
//            }
//            return false;
//        }
//        else return false;
//    }

}
