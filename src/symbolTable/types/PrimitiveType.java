package symbolTable.types;


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
    
    public PrimitiveType(String name){
        super(name);
        if(name.equals("short int")) name = "short";
        else if(name.equals("long int")) name = "long";
        else if(name.equals("long long int")) name = "long long";
        else if(name.equals("unsigned short int")) name = "unsigned short";
        else if(name.equals("unsigned long int")) name = "unsigned long";
        else if(name.equals("unsigned long long int")) name = "unsigned long long";
        this.name = name;
        if(name.equals("bool")){
            this._type = PrimitiveType.bool;
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
