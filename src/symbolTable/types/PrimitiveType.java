package symbolTable.types;

import java.lang.reflect.Array;

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
    
    private static String signedInts[] = {"char", "short", "int", "long", "long long"};
    
    private static String unsignedInts[] = {"unsigned char", "unsigned short", 
                                            "unsigned int", "unsigned long", 
                                            "unsigned long", "unsigned long long"};
    
    private static String doubles[] = {"float", "double", "long double"};
    
    public PrimitiveType(String name){
        super(name);
    }

    @Override
    public boolean subType(Type lhs) {
        throw new UnsupportedOperationException("Not supported yet.");
    }

}
