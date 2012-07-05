/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package symbolTable;

import symbolTable.types.Method;
import symbolTable.types.Type;

/**
 *
 * @author kostas
 */
public interface DefinesNamespace {
    
    public Type findSymbol(String name);
    
    public Type findSymbol(String name, DefinesNamespace fromNamespace);
    
    public DefinesNamespace findNamespace(String name);
    
    public Method findMethod(String name, Method.Signature s);
    
    public Type findField(String name);
}
