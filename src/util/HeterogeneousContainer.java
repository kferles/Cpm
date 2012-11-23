/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package util;

import java.util.HashMap;
import java.util.Map;

/**
 *
 * @author kostas
 */
public class HeterogeneousContainer {
    
    private Map<Class<?>, Object> container = new HashMap<Class<?>, Object>();
    
    public <T> T put(Class<T> key, T value){
        if(key == null) throw new NullPointerException("Key is null");
        return key.cast(this.container.put(key, value));
    }
    
    public <T> T get(Class<T> key){
        return key.cast(container.get(key));
    }
    
}
