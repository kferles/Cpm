package treeNodes4antlr;

import org.antlr.runtime.CommonToken;
import symbolTable.namespace.Namespace;

/**
 *
 * @author kostas
 */
public class UsingDirectiveToken extends CommonToken{

    private Namespace usingNamespace;
    
    public UsingDirectiveToken(int tNode, Namespace usingNamespace){
        super(tNode, "USING_DIRECTIVE");
        this.usingNamespace = usingNamespace;
    }
    
    public Namespace getUsingNamespace(){
        return this.usingNamespace;
    }
    
}
