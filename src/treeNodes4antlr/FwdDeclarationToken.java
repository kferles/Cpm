package treeNodes4antlr;

import org.antlr.runtime.CommonToken;
import symbolTable.types.Type;

/**
 *
 * @author kostas
 */
public class FwdDeclarationToken extends CommonToken {
    
    private Type fwdDeclared;
    
    public FwdDeclarationToken(int tNode, Type fwdDeclared){
        super(tNode, "FWD_DECLARATION");
        this.fwdDeclared = fwdDeclared;
    }
    
    public Type getFwdDeclaration(){
        return this.fwdDeclared;
    }
    
}
