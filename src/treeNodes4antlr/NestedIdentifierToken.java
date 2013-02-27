package treeNodes4antlr;

import org.antlr.runtime.CommonToken;
import symbolTable.namespace.DefinesNamespace;

/**
 *
 * @author kostas
 */
public class NestedIdentifierToken extends CommonToken{
    
    private DefinesNamespace namespace;
    
    private String declarator;
    
    public NestedIdentifierToken(int tNode, DefinesNamespace namespace, String declarator){
        super(tNode, "NESTED_IDENTIFIER");
        this.namespace = namespace;
        this.declarator = declarator;
    }
    
    public DefinesNamespace getNamespace(){
        return this.namespace;
    }
    
    public String getDeclarator(){
        return this.declarator;
    }
    
}
