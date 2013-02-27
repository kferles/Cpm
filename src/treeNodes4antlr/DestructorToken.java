package treeNodes4antlr;

import org.antlr.runtime.CommonToken;
import symbolTable.types.Method;

/**
 *
 * @author kostas
 */
public class DestructorToken extends CommonToken {
    
    private Method destr;
    
    public DestructorToken(int tNode, Method m){
        super(tNode, "DESTRUCTOR");
        this.destr = m;
    }
    
    public Method getDestructor(){
        return this.destr;
    }
    
}
