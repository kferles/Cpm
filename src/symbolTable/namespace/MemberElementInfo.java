/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package symbolTable.namespace;

/**
 *
 * @author kostas
 */
public interface MemberElementInfo<T> {
    
    public String getFileName();
    
    public int getLine();
    
    public int getPos();
    
    public T getElement();
    
}
