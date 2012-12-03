/** ANSI C ANTLR v3 grammar

Translated from Jutta Degener's 1995 ANSI C yacc grammar by Terence Parr
July 2006.  The lexical rules were taken from the Java grammar.

Jutta says: "In 1985, Jeff Lee published his Yacc grammar (which
is accompanied by a matching Lex specification) for the April 30, 1985 draft
version of the ANSI C standard.  Tom Stockfisch reposted it to net.sources in
1987; that original, as mentioned in the answer to question 17.25 of the
comp.lang.c FAQ, can be ftp'ed from ftp.uu.net,
   file usenet/net.sources/ansi.c.grammar.Z.
I intend to keep this version as cu discover discrepancies. Jutta Degener, 1995"

Generally speaking, you need symbol table info to parse C; typedefs
define types and then IDENTIFIERS are either types or plain IDs.  I'm doing
the min necessary here tracking only type names.  This is a good example
of the global scope (called Symbols).  Every rule that declares its usage
of Symbols pushes a new copy on the stack effectively creating a new
symbol scope.  Also note rule declaration declares a rule scope that
lets any invoked rule see isTypedef boolean.  It's much easier than
passing that info down as parameters.  Very lose to the current C Standard grammar as
possible; please let me know if yoclean.  Rule
direct_declarator can then easily determine whether the IDENTIFIER
should be declared as a type name.

I have only tested this on a single file, though it is 3500 lines.

This grammar requires ANTLR v3.0.1 or higher.

Terence Parr
July 2006
*/
grammar Cpm;
options {
    backtrack=true;
    memoize=true;
    k=2;
    output=AST;
}

scope Type_Spec{
	boolean error_for_signed, error_for_unsigned, error_for_short;
	boolean type[];
	//primitive types 
	PrimitiveTypeCheck counters;
	
	//user defined types
	TypeDefinition named_t;
	int userDefinedCount;
	boolean error_inUserDefined;
	
	//forward declaration
	boolean isForwardDeclaration;
}

scope cv_qual{
	boolean error_for_const, error_for_volatile;
	int constCount;
	int volatileCount;
}

scope storage_class_spec{
	boolean error_found;
	int externCount;
	int staticCount;
	int autoCount;
	int registerCount;
}

scope function_spec{
	boolean error_for_explicit;
	boolean error_for_virtual;
	int explicitCount;
	int virtualCount;
}

scope declarator_strings{
	String dir_decl_identifier;
	String dir_decl_error;
}

scope decl_infered{
	DeclaratorInferedType declarator;
}

scope decl_id_info{
	int line;
	int pos;
}

scope collect_base_classes{
	ArrayList<CpmClass> superClasses;
}

scope normal_mode_fail_level{
	boolean failed;
}

scope parameters_id{
	ArrayList<String> parameters_ids;
}

@header {
import java.util.Set;
import java.util.HashSet;
import java.util.ArrayList;
import java.util.List;
import java.util.Stack;
import symbolTable.SymbolTable;
import symbolTable.types.*;
import symbolTable.namespace.*;
import symbolTable.namespace.stl.container.StlContainer;
import errorHandling.*;
import preprocessor.*;
}

@parser::members {

	//Symbol Table
	private SymbolTable symbolTable = new SymbolTable();
	
	//Preprocessor Information
	PreprocessorInfo preproc = new PreprocessorInfo();

	boolean inStlFile = false;
	
	String stlFile = null;
	
	//error messages
	
	private class DeclSpecifierError extends Exception{
	
		String error, init_delc_list_err;

		public DeclSpecifierError(String error, String init_decl_list_err){
			this.error = error;
			this.init_delc_list_err = init_decl_list_err;
		}

	}

	Stack paraphrases = new Stack();
	
	String pending_undeclared_err = null;
	
	AmbiguousReference pending_ambiguous = null;
	
	AccessSpecViolation pending_access_viol = null;
	
	private void resetErrorMessageAuxVars(){
		this.pending_undeclared_err = null;
		this.pending_ambiguous = null;
		this.pending_access_viol = null;
	}
	
	//to change the name of the file when i'll use the cpp utility
	//just override this on
	public String getSourceName(){
		return this.preproc.getCurrentFileName();
	}

	public void displayRecognitionError(String[] tokenNames, RecognitionException e) {
		//Change line number in error reporting HERE !!!!
		//System.out.println(e.input.getSourceName());
		//ugly, ugly ... But there is no obvious way to avoid it
		if(this.pending_undeclared_err == null &&
		   this.pending_ambiguous == null &&
		   this.pending_access_viol == null){
			if( e instanceof EarlyExitException ) return;
		}

		System.err.print(this.preproc.getHeaderError());
		e.line = this.preproc.getOriginalFileLine(e.line);
		super.displayRecognitionError(tokenNames, e);
        }
	
	public String getErrorMessage(RecognitionException e, String[] tokenNames){
		//e.token.setLine(e.token.getLine()+1);
		
		if(paraphrases.size() > 0){
			String rv = "";
			for(Object o : paraphrases)
				rv += (String) o;
			paraphrases.clear();
			return rv;
		}
		if(pending_undeclared_err != null) {
			String rv = pending_undeclared_err;
			pending_undeclared_err = null;
			return rv;
		}
		if(pending_ambiguous != null){
			AmbiguousReference temp = pending_ambiguous;
			pending_ambiguous = null;
			yield_error(temp.getRefError(), true);
		  	System.err.print(temp.getMessage());
		  	return temp.getLastLine();
		}
		if(pending_access_viol != null){
			AccessSpecViolation temp = pending_access_viol;
			pending_access_viol = null;
			yield_error(temp.getMessage(), false);
		  	return temp.getContextError();
		}
		return super.getErrorMessage(e, tokenNames);
	}
	
	private Object error(String msg){
		paraphrases.push(msg);
		//throw new RecognitionException();
		return null;
	}
	
	private int fixLine(Token t){
		return this.preproc.getOriginalFileLine(t.getLine());
	}
	
	private void yield_error(String error, boolean need_file_name){
		if(need_file_name){
			String fileName = this.getSourceName();
			error = fileName + " " + error;
		}
		System.err.println(error);
	} 
	
	private void yield_error(String error, int line, int position){
		String fileName = this.getSourceName();
		error = fileName + " line " + line + ":" + position + " " + error;
		System.err.print(this.preproc.getHeaderError());
		System.err.println(error);
	}
	
	private void direct_declarator_error(String declarator, int line, int position, String error){
		if(error == null) return;
		String fileName = super.getSourceName();
		error = error + " '" + declarator + '\'';
		yield_error(error, line, position);
		//paraphrases.push(error);
	}
	
	private boolean not_null_decl_id(String decl_id, String decl_spec_err, Token declarator_start){
		if(decl_id == null){
			if(decl_spec_err != null)
				this.yield_error(decl_spec_err.substring(0, decl_spec_err.lastIndexOf(" ")),
						 this.fixLine(declarator_start),
						 declarator_start.getCharPositionInLine());
			return false;
		}
		return true;
	}
	
	private boolean const_count_error(){
		cv_qual_scope cv_quals = get_cv_qual_scope();
		if(cv_quals.error_for_const == true) return true;
		if(cv_quals.constCount > 1){
			cv_quals.error_for_const = true;
			paraphrases.push("error: duplicate 'const'");
			return false;
		}
		return true;
	}
	
	private boolean volatile_count_error(){
		cv_qual_scope cv_quals = get_cv_qual_scope();
		if(cv_quals.error_for_volatile == true) return true;
		if(cv_quals.volatileCount > 1){
			cv_quals.error_for_volatile = true;
			paraphrases.push("error: duplicate 'volatile'");
			return false;
		}
		return true;
	}
	
	private boolean virtual_count_error(){
		function_spec_scope fun_spec = get_function_spec_scope();
		if(fun_spec.error_for_virtual == true) return true;
		if(fun_spec.virtualCount > 1){
			fun_spec.error_for_virtual = true;
			paraphrases.push("error: duplicate 'virtual'");
			return false;
		}
		return true;
	}
	
	private boolean explicit_count_error(){
		function_spec_scope fun_spec = get_function_spec_scope();
		if(fun_spec.error_for_explicit == true) return true;
		if(fun_spec.explicitCount > 1){
			fun_spec.error_for_explicit = true;
			paraphrases.push("error: duplicate 'explicit'");
			return false;
		}
		return true;
	}
	
	private boolean storage_class_specs_error(){
		storage_class_spec_scope specs = get_storage_class_spec();
		if(specs.error_found == true) return true;
		if(specs.externCount
		   + specs.staticCount
		   + specs.autoCount
		   + specs.registerCount > 1){
		
			specs.error_found = true;
			paraphrases.push("error: conflicting or duplicated storage class specifiers");
		  	return false;
		}
		return true;
	}
	
	private boolean signed_count_error(){
		Type_Spec_scope specs = get_Type_Spec_scope();
		if(specs.error_for_signed == true) return true;
		if(specs.counters.signedCount > 1){
			specs.error_for_signed = true;
			paraphrases.push("error: duplicate 'signed'");
			return false;
		}
		return true;
	}
	
	private boolean unsigned_count_error(){
		Type_Spec_scope specs = get_Type_Spec_scope();
		if(specs.error_for_unsigned == true) return true;
		if(specs.counters.unsignedCount > 1){
			specs.error_for_unsigned = true;
			paraphrases.push("error: duplicate 'unsigned'");
			return false;
		}
		return true;
	}
	
	private boolean short_count_error(){
		Type_Spec_scope specs = get_Type_Spec_scope();
		if(specs.error_for_short == true) return true;
		if(specs.counters.shortCount > 1){
			specs.error_for_short = true;
			paraphrases.push("error: duplicate 'short'");
			return false;
		}
		return true;
	}

	private boolean check_tags(String requested, TypeDefinition original, int line, int pos){
		String tag = original.getTag();
		boolean isUnion = requested.equals("union");
		if(tag.equals("struct") == true || tag.equals("class") == true){
			if(isUnion){
				this.yield_error("error: 'union' tag used in naming '" + original.toString() + "'", line, pos);
				return false;
			}
		}
		else if(tag.equals("union") == true){
			if(!isUnion){
				this.yield_error("error: '" + requested + "' tag used in nameing '" + original.toString() + "'", line, pos);
				return false;
			}
		}
		
		return true;
	}
	
	//end error messages
	
	//AST construction
	
	Tree getChildren(CommonTree t){
		List l = t.getChildren();
		CommonTree rv = new CommonTree();
		if(l != null)
			for(Object o : l) rv.addChild((CommonTree)o);
		return rv;
	}
	
	Tree createTreeFromList(List nodes){
		CommonTree rv = new CommonTree();
		if(nodes != null)
			for(Object o : nodes) rv.addChild((CommonTree)o);
		return rv;
	}
	
	//end AST construction
	
	//Scopes
	
	//Type_Spec scope
	private class PrimitiveTypeCheck{
		int voidCount = 0,
		    charCount = 0,
		    shortCount = 0,
		    intCount = 0,
		    longCount = 0,
		    floatCount = 0,
		    doubleCount = 0,
		    boolCount = 0,
		    signedCount = 0,
		    unsignedCount = 0;
		    
		public Type checkSpecForPrimitives(boolean isConst, boolean isVolatile) throws DeclSpecifierError{
			int countDataTypes = voidCount + charCount   + intCount    
						       + floatCount  + doubleCount
						       + boolCount;
			
			int signs = signedCount + unsignedCount;

			//if(countDataTypes == 0) return; //error //is that possible?
			if(countDataTypes > 1) {
				throw new DeclSpecifierError("error: two or more data types in declaration", " of");
			}
			
			if(signedCount > 1 && unsignedCount > 1) {
				throw new DeclSpecifierError("error: 'signed' and 'unsigned' specified together", " for");
			}
			
			String type_name = "";
			
			if(voidCount == 1){
				if(signs != 0) {
					throw new DeclSpecifierError("error: 'signed' or 'unsigned' invalid", " for");
				}
				if(longCount != 0 || shortCount != 0) {
					throw new DeclSpecifierError("error: 'long' or 'short' invalid", " for");
				}
				type_name += "void";
			}
			else if(charCount == 1){
				if(longCount != 0 || shortCount != 0) {
					throw new DeclSpecifierError("error: 'long' or 'short' invalid", " for");
				}
				type_name += unsignedCount == 1 ? "unsigned " : "" + "char";
			}
			else if(intCount == 1){
				if(longCount > 0 && shortCount > 0){
					throw new DeclSpecifierError("error: 'long' and 'short' specified together", " for");
				}
				type_name += unsignedCount == 1 ? "unsigned " : "";
				if(longCount != 0){
					if(longCount > 2) {
						throw new DeclSpecifierError("error: 'long long long' invalid", " for");
					}
					for(int i = 0 ; i < longCount ; ++i) type_name += "long ";
				}
				else if(shortCount != 0){
					type_name += "short";
				}
				else{
					type_name += "int";
				}
			}
			else if(floatCount == 1){
				if(signs != 0) {
					throw new DeclSpecifierError("error: 'signed' or 'unsigned' invalid", " for");
				}
				if(longCount != 0 || shortCount != 0) {
					throw new DeclSpecifierError("error: 'long' or 'short' invalid", " for");
				}
				type_name += "float";
			}
			else if(doubleCount == 1){
				if(signs != 0) {
					throw new DeclSpecifierError("error: 'signed' or 'unsigned' invalid", " for");
				}
				if(shortCount > 1){
					throw new DeclSpecifierError("error: 'short' invalid", " for");
				}
				if(longCount > 1) {
					throw new DeclSpecifierError("error: 'long long' invalid", " for");
				}
				type_name += longCount == 1 ? "long " : "" + "double";
			}
			else if(boolCount == 1){
				if(signs != 0) {
					throw new DeclSpecifierError("error: 'signed' or 'unsigned' invalid", " for");
				}
				if(longCount != 0 || shortCount != 0) {
					throw new DeclSpecifierError("error: 'long' or 'short' invalid", " for");
				}
				type_name += "bool";
			}
			else if(shortCount != 0 && longCount == 0){
				type_name += unsignedCount == 1 ? "unsigned " : "" + "short";
			}
			else if(longCount != 0 && shortCount == 0){
				if(longCount > 2) {
					throw new DeclSpecifierError("error: 'long long long' invalid", " for");
				}
				type_name += unsignedCount == 1 ? "unsigned " : "";
				if(longCount == 1) type_name += "long";
				if(longCount == 2) type_name += "long long";
			}
			else{
				throw new DeclSpecifierError("error: 'long' and 'short' specified together", " for");
			}
			
			return new PrimitiveType(type_name, isConst, isVolatile);
		}
	}
	
	private Type_Spec_scope get_Type_Spec_scope(){
		Stack type_specs = Type_Spec_stack;
		return (Type_Spec_scope)type_specs.get(type_specs.size() - 1);
	}
	
	private void Type_Spec_at_init(){
		Type_Spec_scope specs = get_Type_Spec_scope();
		specs.error_for_signed = false;
		specs.error_for_unsigned = false;
		specs.type = new boolean[]{false,		//indicades primitive
					   false};		//user defined type
		specs.counters = new PrimitiveTypeCheck();
		specs.named_t = null;
		specs.userDefinedCount = 0;
		
		specs.isForwardDeclaration = false;
	}
	
	//End Type_Spec scope
	
	//cv_qual scope
	
	private cv_qual_scope get_cv_qual_scope(){
		Stack cv_qual_st = cv_qual_stack;
		return (cv_qual_scope)cv_qual_st.get(cv_qual_st.size() - 1);
	}
	
	
	private void cv_qual_at_init(){
		cv_qual_scope cv_quals = get_cv_qual_scope();
		cv_quals.constCount = cv_quals.volatileCount = 0;
		cv_quals.error_for_const = false;
		cv_quals.error_for_volatile = false;
	}
	//end cv_qual scope
	
	//function_spec scope
	
	private function_spec_scope get_function_spec_scope(){
		Stack function_spec_st = function_spec_stack;
		return (function_spec_scope)function_spec_st.get(function_spec_st.size() - 1);
	}
	
	private void function_spec_at_init(){
		function_spec_scope fun_specs = get_function_spec_scope();
		fun_specs.error_for_explicit = false;
		fun_specs.error_for_virtual = false;
		fun_specs.explicitCount = 0;
		fun_specs.virtualCount = 0;
	}
	
	//end function_spec scope
	
	//storage_class_spec
	
	private storage_class_spec_scope get_storage_class_spec(){
		Stack storage_class_spec_st = storage_class_spec_stack;
		return (storage_class_spec_scope) storage_class_spec_st.get(storage_class_spec_st.size() - 1);
	}
	
	private void storage_class_spec_at_init(){
		storage_class_spec_scope specs = get_storage_class_spec();
		specs.error_found = false;
		specs.externCount = 0;
		specs.staticCount = 0;
		specs.autoCount = 0;
		specs.registerCount = 0;
	}
	
	//end storage_class_spec
	
	//nested name id as type specifier aux methods and fields
	
	HashMap<ArrayList<SymbolTable.NestedNameInfo>, TypeDefinition> successes = new HashMap<ArrayList<SymbolTable.NestedNameInfo>, TypeDefinition>();
	
	HashSet<SymbolTable.NestedNameInfo> failures = new HashSet<SymbolTable.NestedNameInfo>();
	
	private TypeDefinition getNamedType(ArrayList<SymbolTable.NestedNameInfo> chain, boolean explicitGlobalScope, boolean isTemplate, List<List<Type>> tmplArgs){
		TypeDefinition rv;
		
		if(isTemplate == true){
			rv = this.symbolTable.instantiateTemplates(chain, explicitGlobalScope, tmplArgs);
		}
		else{
			rv = successes.get(chain);
		}
		/*
		 * todo: clear maps more oftens
		 */
		//successes.clear();
		//failures.clear();
		return rv;
	}
	
	private boolean isValidNamedType(ArrayList<SymbolTable.NestedNameInfo> chain, boolean explicitGlobalScope){
		TypeDefinition t = null;

		/*if(chain.size() == 1 && chain.get(0).getName().equals("list") == true) {
			System.out.println("Here");
			return true; 
		}*/

		if(chain.isEmpty() == true) {
			return false;
		}
		
		/*
		 * if chain is a key in the successes HashMap retrun treu
		 */
		if(successes.containsKey(chain) == true) {
			return true;
		}
		
		/*
		 * if the arrayList has at least one identifier inside the failures return false
		 */
		for(SymbolTable.NestedNameInfo inf : chain)
			if(failures.contains(inf) == true){
				return false; 
			}

		try{
			t = symbolTable.getNamedTypeFromNestedNameId(chain, explicitGlobalScope, false, false);
		}
		catch(AccessSpecViolation access_viol){
			//if chain size is 1 the error must be pending
			if(chain.size() > 1){
		  		yield_error(access_viol.getMessage(), false);
		  		yield_error(access_viol.getContextError(), true);
	  		}
	  		else{
	  			this.pending_access_viol = access_viol;
	  		}

	  	}
	  	catch(AmbiguousReference ambiguous){
	  		if(ambiguous.isPending() == false){
		  		yield_error(ambiguous.getRefError(), true);
		  		System.err.print(ambiguous.getMessage());
		  		yield_error(ambiguous.getLastLine(), true);
	  		}
	  		else{
	  			pending_ambiguous = ambiguous;
	  		}
	  	}
	  	catch(NotDeclared nodeclared){
  			yield_error(nodeclared.getMessage(), true);
	  	}
	  	catch(InvalidScopeResolution invalid){
	  		yield_error(invalid.getMessage(), true);
	  	}
	  	catch(DoesNotNameType nt){
	  		pending_undeclared_err = nt.getMessage();
	  	}

	  	if(t == null){
	  		for(SymbolTable.NestedNameInfo inf : chain)
	  			this.failures.add(inf);
	  	}
	  	else{
	  		this.successes.put(chain, t);
	  	}
	  	
	  	return t == null ? false : true;
	}
	
	private CpmClass isValidBaseClass(ArrayList<SymbolTable.NestedNameInfo> chain, boolean explicitGlobalScope, char token) throws Exception, BaseClassCVQual{
		CpmClass rv = null;
		try{
			TypeDefinition named_t = symbolTable.getNamedTypeFromNestedNameId(chain, explicitGlobalScope, false, false);
			rv = named_t.isClassName();
			if(rv == null){
				throw new Exception("error: expected class-name before '" + token + "'");
			}
		}
		catch(AccessSpecViolation access_viol){
	  		yield_error(access_viol.getMessage(), false);
	  		yield_error(access_viol.getContextError(), true);
	  	}
	  	catch(AmbiguousReference ambiguous){
	  		if(ambiguous.isPending() == false){
		  		yield_error(ambiguous.getRefError(), true);
		  		System.err.print(ambiguous.getMessage());
		  		yield_error(ambiguous.getLastLine(), true);
	  		}
	  		else{
	  			throw new Exception("error: expected class-name before '" + token + "'");
	  		}
	  	}
	  	catch(NotDeclared nodeclared){
  			throw new Exception("error: expected class-name before '" + token + "'");
	  	}
	  	catch(InvalidScopeResolution invalid){
	  		throw new Exception("error: expected class-name before '" + token + "'");
	  	}
	  	catch(DoesNotNameType nt){
	  		throw new Exception("error: expected class-name before '" + token + "'");
	  	}
	  	
	  	return rv;
	}
	
	//end nested name id as type specifier aux methods
	
	//declarator aux class and methods (to infer the type)
	
	private class ptr_cv{
	
		boolean isConst;
		
		boolean isVolatile;
	
		public ptr_cv(boolean isConst, boolean isVolatile){
			this.isConst = isConst;
			this.isVolatile = isVolatile;
		}
	}
	
	private class DeclaratorInferedType{
	
		Pointer p_rv = null;
		
		Method m_rv = null;
		
		CpmArray ar_rv = null;
		
		
		/*
		 * Pending types only one of the follow not null
		 */
		
		Pointer p_pend = null;
		
		Method m_pend = null;
		
		CpmArray ar_pend = null;
		
		public DeclaratorInferedType(Pointer p_rv, Pointer pending){
			this.p_rv = p_rv;
			this.p_pend = pending;
		}
		
		public DeclaratorInferedType(Method m_rv){
			this.m_rv = m_rv;
			this.m_pend = m_rv;
		}
		
		public DeclaratorInferedType(CpmArray ar_rv){
			this.ar_rv = ar_rv;
			this.ar_pend = ar_rv;
		}
		
		public void setPending(Pointer ptr, Pointer new_pending){
			if(this.p_pend != null){
				this.p_pend.setPointsTo(ptr);
				
			}
			else if(this.m_pend != null){
				this.m_pend.getSignature().setReturnValue(ptr);
				this.m_pend = null;
			}
			else if(ar_pend != null){
				this.ar_pend.setType(ptr);
				this.m_pend = null;
			}
			else return;
			
			this.p_pend = new_pending;
		}
		
		public void setPending(CpmArray ar) throws Exception{
			if(p_pend != null){
				this.p_pend.setPointsTo(ar);
				this.p_pend = null;
				this.ar_pend = ar;
			}
			else if(m_pend != null){
				this.m_pend = null;
				throw new Exception("declared as a function returning an array");
			}
			else if(ar_pend != null){
				this.ar_pend.increaseDimensions();
			}
		}
		
		public void setPending(Method m) throws Exception{
			
			if(p_pend != null){
				this.p_pend.setPointsTo(m);
				this.p_pend = null;
				this.m_pend = m;
			}
			else if(m_pend != null){
				this.m_pend = null;
				throw new Exception("declared as function returning a fuction");
			}
			else if(ar_pend != null){
				this.ar_pend = null;
				throw new Exception("declared as as array of functions");
			}
			
		}
	
	}
	
	//end declarator aux class and methods (to infer the type)
	
	//class for in class declarations specifiers
	
	private class InClassDeclSpec{
	
		boolean isVirtual;
		
		boolean isExplicit;
		
		boolean isStatic;
		
		public InClassDeclSpec(boolean isVirtual, boolean isExplicit, boolean isStatic){
			this.isVirtual = isVirtual;
			this.isExplicit = isExplicit;
			this.isStatic = isStatic;
		}
	}
	
	//end class for in class declarations specifiers
	
	//classes to collect all parametrs
	
	private class Param{
		Type t;
		String id;
	}
	
	private class ParameterList{
	
		ArrayList<Type> params = null;
		
		ArrayList<String> ids = null; 
		
		boolean hasVarargs = false;
	
		void insertParam(Param p){
			if(this.params == null){
				this.params = new ArrayList<Type>();
				this.ids = new ArrayList<String>();
			}
			
			this.params.add(p.t);
			this.ids.add(p.id);
		}
	}
	
	//end classes to collect all parametrs
	
	//insert into current scope
	
	private Namespace insertNamespace(String name, Namespace _namespace){
		Namespace rv = null;
		try{
			rv = this.symbolTable.insertNamespace(name, _namespace);
		}
		catch(DiffrentSymbol diff){
			this.yield_error(diff.getMessage(), true);
			this.yield_error(diff.getFinalError(), false);
		}
		
		return rv;
	}
	
	private CpmClass insertClass(String name, CpmClass cpm_class){
		CpmClass rv = null;
		try{
			//for now static will be false for all types
			//if there is an actuall diff for static specifier i'll change this one
			rv = this.symbolTable.insertInnerType(name, cpm_class, false);
		}
		catch(SameNameAsParentClass same_name){
			this.yield_error(same_name.getMessage(), true);
		}
		catch(ConflictingDeclaration conflict){
			this.yield_error(conflict.getMessage(), true);
			this.yield_error(conflict.getFinalError(), false);
		}
		catch(Redefinition redef){
			this.yield_error(redef.getMessage(), true);
			this.yield_error(redef.getFinalError(), false);
		}
		catch(DiffrentSymbol diff){
			this.yield_error(diff.getMessage(), true);
			this.yield_error(diff.getFinalError(), false);
		}
		return rv;
	}
	
	private void insertSynonym(String declarator_id, Type data_type, int id_line, int id_pos, InClassDeclSpec class_specs){
		try{
			SynonymType syn = new SynonymType(declarator_id, data_type, this.symbolTable.getCurrentNamespace());
			syn.setLineAndPos(id_line, id_pos);
			
	  		if(class_specs.isStatic == true){
				this.yield_error("error: conflicting specifiers in declaration of '" + declarator_id +"'", id_line, id_pos);
			}
			else if(class_specs.isVirtual == true){
				this.yield_error("error: '" + declarator_id + "' declared as virtual type", id_line, id_pos);	
			}
			else if(class_specs.isExplicit == true){
				this.yield_error("error: only declarations of constructors can be 'explicit'", id_line, id_pos);
			}
			else{
				this.symbolTable.insertInnerSyn(declarator_id, syn);
			}
		}
		catch(SameNameAsParentClass sameName){
			this.yield_error(sameName.getMessage(), true);
		}
                catch(ConflictingDeclaration conflict){
                	this.yield_error(conflict.getMessage(), true);
                	this.yield_error(conflict.getFinalError(), false);
                }
                catch(Redefinition redef){
                	this.yield_error(redef.getMessage(), true);
                	this.yield_error(redef.getFinalError(), false);
                }
                catch(DiffrentSymbol diffSymbol){
                	this.yield_error(diffSymbol.getMessage(), true);
                	this.yield_error(diffSymbol.getFinalError(), false);
                }
	}
	
	private void insertField(String declarator_id, Type t, int id_line, int id_pos, InClassDeclSpec class_specs){
		
		try{
			if(class_specs.isVirtual == true){
				this.yield_error("error: '" + declarator_id + "' declared as virtual type", id_line, id_pos);
			}
			else if(class_specs.isExplicit == true){
				this.yield_error("error: only declarations of constructors can be 'explicit'", id_line, id_pos);
			}
			else{
				CpmClass currentClass = null;
				if(this.symbolTable.isCurrentNamespaceClass() == true){
					currentClass = (CpmClass) this.symbolTable.getCurrentNamespace();
				}
				
				if(t.isComplete(currentClass) == true){
					this.symbolTable.insertField(declarator_id, t, class_specs.isStatic, this.preproc.getCurrentFileName(), id_line, id_pos);
				}
				else{
					this.yield_error("error: field '" + declarator_id + "' has incomplete type", id_line, id_pos);
				}
			}
		}
		catch(ConflictingDeclaration conflict){
                	this.yield_error(conflict.getMessage(), true);
                	this.yield_error(conflict.getFinalError(), false);
                }
                catch(DiffrentSymbol diffSymbol){
                	this.yield_error(diffSymbol.getMessage(), true);
                	this.yield_error(diffSymbol.getFinalError(), false);
                }
                catch(ChangingMeaningOf changeMean){
                	this.yield_error(changeMean.getMessage(), true);
                	this.yield_error(changeMean.getFinalError(), false);
                }
                catch(VoidDeclaration v_decl){
                	this.yield_error(v_decl.getMessage(declarator_id), id_line, id_pos);
                }
	}
	
	private void insertMethod(String declarator_id, Method m, int id_line, int id_pos, InClassDeclSpec class_specs){
	
		try{
			if(class_specs.isExplicit == true){
				this.yield_error("error: only declarations of constructors can be 'explicit'", id_line, id_pos);
			}
			else{
				m.setVirtual(class_specs.isVirtual);
				this.symbolTable.insertMethod(declarator_id, m, class_specs.isStatic, this.preproc.getCurrentFileName(), id_line, id_pos);
			}
		}
		catch(ConflictingDeclaration conflict){
                	this.yield_error(conflict.getMessage(), true);
                	this.yield_error(conflict.getFinalError(), false);
                } 
                catch(ChangingMeaningOf changeMean){
                	this.yield_error(changeMean.getMessage(), true);
                	this.yield_error(changeMean.getFinalError(), false);
                }
                catch(CannotBeOverloaded cBeoverld){
                	this.yield_error(cBeoverld.getMessage(), true);
                	this.yield_error(cBeoverld.getFinalError(), false);
                }
                catch(DiffrentSymbol diffSymbol){
                	this.yield_error(diffSymbol.getMessage(), true);
                	this.yield_error(diffSymbol.getFinalError(), false);
                }
                catch(ConflictingRVforVirtual confRv){
                	this.yield_error(confRv.getMessage(id_line, id_pos), true);
                	this.yield_error(confRv.getFinalError(), false);
                }
                catch(InvalidCovariantForVirtual invalidCovariant){
                	this.yield_error(invalidCovariant.getMessage(id_line, id_pos), true);
                	this.yield_error(invalidCovariant.getFinalError(), false);
                }
                catch(Redefinition redef){
                	this.yield_error(redef.getMessage(), true);
                	this.yield_error(redef.getFinalError(), false);
                }
	
	}
	
	//end insert into current scope

	boolean normal_mode = true;
	
	//using directive aux methods 
	
	

}

@synpredgate{ this.state.backtracking == 0 && this.normal_mode == true }


translation_unit
	: external_declaration+
	;
	
/** Either a function definition or any other kind of C decl/def.
 *  The LL(*) analysis algorithm fails to deal with this due to
 *  recursion in the declarator rules.  I'm putting in a
 *  manual predicate here so that we don't backtrack over
 *  the entire function.  Further, you get a better error
 *  as errors within the function itself don't make it fail
 *  to predict that it's a function.  Weird errors previously.
 *  Remember: the goal is to avoid backtrack like the plague
 *  because it makes debugging, actions, and errors harder.
 *
 *  Note that k=1 results in a much smaller predictor for the 
 *  fixed lookahead; k=2 made a few extra thousand lines. ;)
 *  I'll have to optimize that in the future.
 */
external_declaration
//options {k=1;}
	: namespace_definition
	//| (/*!!!*/nested_name_id '::' declarator[null] '{') => extern_method_definition
	| ( declaration_specifiers declarator '{' )=> function_definition
	| declaration
	;

namespace_definition
scope normal_mode_fail_level;
@init{
	$normal_mode_fail_level::failed = false;
}
	: 'namespace' IDENTIFIER 
	  {
  	  	String name = $IDENTIFIER.text;
	  	Namespace _namespace = new Namespace(name, this.symbolTable.getCurrentNamespace());
	  	_namespace.setLineAndPos(this.fixLine($IDENTIFIER), $IDENTIFIER.pos);
	  	_namespace.setFileName(this.preproc.getCurrentFileName());
	  	_namespace = this.insertNamespace(name, _namespace);
	  	if(_namespace != null){
	  		this.symbolTable.setCurrentScope(_namespace);
	  		this.symbolTable.setCurrentAccess(null);
	  	}
	  	else{
	  		this.normal_mode = false;
	  		$normal_mode_fail_level::failed = true;
	  	}
	  }
	  '{' external_declaration*  '}'
	  {
  	  	this.symbolTable.endScope();
  	  }
	   turn_on_normal_mode
	;
	
extern_method_definition
	: type_specifier nested_name_id '::' declarator compound_statement
	;
	
function_definition
scope{
	Method methods_type;
}
scope declarator_strings;
scope decl_infered;
scope normal_mode_fail_level;
scope parameters_id;
@init{
	$declarator_strings::dir_decl_identifier = null;
	$declarator_strings::dir_decl_error = null;
	$decl_infered::declarator = null;
	$parameters_id::parameters_ids = null;
	$function_definition::methods_type = null;
	
	$normal_mode_fail_level::failed = false;
	
	this.resetErrorMessageAuxVars();
}
	: simple_declaration
	  {
	  	Method m = $function_definition::methods_type;
	  	if(m == null){
	  		Token st = $simple_declaration.stop;
	  		this.yield_error("error: expecting function definition",
	  				  this.fixLine(st),
	  				  st.getCharPositionInLine());
	  		this.normal_mode = false;
	  		$normal_mode_fail_level::failed = true;
	  	}
	  } //here and in constructor, error if identifiers are missing ...
	  compound_statement turn_on_normal_mode	// ANSI style only
	;

declaration
options{ k = 3; }
scope{
  boolean isTypedef;
}
@init{
  $declaration::isTypedef = false;
}
@after {
  this.resetErrorMessageAuxVars();
}
	: (struct_union_or_class IDENTIFIER ':' 'public') => struct_union_or_class_definition ';'
	| (struct_union_or_class IDENTIFIER '{') => struct_union_or_class_definition ';'
	| (struct_union_or_class nested_name_id ':' 'public') => extern_class_definition ';'
	| (struct_union_or_class nested_name_id '{') => extern_class_definition ';'
	|'typedef' { $declaration::isTypedef = true; } simple_declaration ';'
	| simple_declaration ';'
	| using_directive ';'
	| line_marker
	;

using_directive
scope{
	Namespace currUsing;
	DefinesNamespace currentScope;
	Namespace finalNamespace;
}
@init{
	$using_directive::finalNamespace = null;
}
	: us = 'using' 'namespace' global_scope = '::'? IDENTIFIER 
	{
	   DefinesNamespace curr = null;
	   String id = $IDENTIFIER.text;
	   DefinesNamespace currentScope = this.symbolTable.getCurrentNamespace();
	   
	   $using_directive::currentScope = currentScope;
	   
	   try{
		   if($global_scope != null){
		   	curr = this.symbolTable.findNamespace(id, currentScope, false);
		   }
		   else{
		   	curr = currentScope.findNamespace(id, currentScope, false);
		   }
		   
		   if(!(curr instanceof Namespace)) curr = null;
	   }
	   catch(ErrorMessage _){
	   	
	   }
	   
	   if(curr == null){
	   	this.yield_error("error: '" + id + "' is not a namespace-name", this.fixLine($IDENTIFIER), $IDENTIFIER.pos);
	   	
	   	Token nextToken = this.input.LT(1);
	   	
	   	this.yield_error("error: expected namespace-name before '" + nextToken.getText() + "' token", this.fixLine(nextToken), nextToken.getCharPositionInLine());
	   }
	   else{
	   	$using_directive::finalNamespace = (Namespace) curr;
	   }
	}
	using_directive_tail[$using_directive::currUsing, $using_directive::currentScope]?
	{
	   if(this.symbolTable.isCurrentNamespaceClass() == true){
	   	this.yield_error("error: using directives are only allowed within namespaces", this.fixLine($us), $us.getCharPositionInLine());
	   }
	   else{
	   	if($using_directive::finalNamespace != null){
	   		((Namespace) $using_directive::currentScope).insertUsingDirective($using_directive::finalNamespace);
	   	}
	   }
	}
	;

using_directive_tail [Namespace currentNamespace, DefinesNamespace currentScope]
scope{
	Namespace currNamespace;
	DefinesNamespace currScope;
}
@init{
	$using_directive_tail::currNamespace = null;
	$using_directive_tail::currScope = $currentScope;
}
	: '::' IDENTIFIER 
	  {	String id = $IDENTIFIER.text;
	  	DefinesNamespace tmp = null;
	  	if(currentNamespace != null){
		  	try{
		  		tmp = $currentNamespace.findNamespace(id, $currentScope, false);
		  		
		  		if(!(tmp instanceof Namespace)) $using_directive_tail::currNamespace = null;
		  		else $using_directive_tail::currNamespace = (Namespace) tmp;
		  	}
		  	catch(ErrorMessage _){
		  	
		  	}
		  	
		  	if($using_directive_tail::currNamespace == null){
		  		this.yield_error("error: '" + id + "' is not a namespace-name", this.fixLine($IDENTIFIER), $IDENTIFIER.pos);
	   	
			   	Token nextToken = this.input.LT(1);
			   	
			   	this.yield_error("error: expected namespace-name before '" + nextToken.getText() + "' token",
			   			 this.fixLine(nextToken), 
			   			 nextToken.getCharPositionInLine());
		  	}
	  	}
	  }
	  using_directive_tail[$using_directive_tail::currNamespace, $using_directive_tail::currScope]
	| '::' IDENTIFIER
	  {
	  	String id = $IDENTIFIER.text;
	  	DefinesNamespace tmp = null;
	  	if(currentNamespace != null){
		  	try{
		  		tmp = $currentNamespace.findNamespace(id, $currentScope, false);
		  		
		  		if(!(tmp instanceof Namespace)) $using_directive_tail::currNamespace = null;
		  	}
		  	catch(ErrorMessage _){
		  	
		  	}
		  	
		  	if($using_directive_tail::currNamespace == null){
		  		this.yield_error("error: '" + id + "' is not a namespace-name", this.fixLine($IDENTIFIER), $IDENTIFIER.pos);
	   	
			   	Token nextToken = this.input.LT(1);
			   	
			   	this.yield_error("error: expected namespace-name before '" + nextToken.getText() + "' token",
			   			 this.fixLine(nextToken), 
			   			 nextToken.getCharPositionInLine());
		  	}
		  	else{
		  		$using_directive::finalNamespace = $using_directive_tail::currNamespace;
		  	}
	  	}
	  }
	;

simple_declaration
scope{
	boolean possible_fwd_decl;
	SymbolTable.NestedNameInfo inf;
	String tag;
	boolean isEnumDef;
	String enumId;
}
@init{
	$simple_declaration::possible_fwd_decl = false;
	$simple_declaration::inf = null;
	$simple_declaration::tag = null;
	$simple_declaration::isEnumDef = false;
	$simple_declaration::enumId = null;
}
 	:
	  declaration_specifiers
	  decl_list = init_declarator_list[$declaration_specifiers.error != null ? $declaration_specifiers.error + $declaration_specifiers.init_decl_err : null,
	  				   $declaration_specifiers.t,
	  				   $declaration_specifiers.class_specs]?
	  {
	      if($decl_list.tree == null){
	      	  if($declaration_specifiers.isFwdDecl == false){
	      	  	if($simple_declaration::possible_fwd_decl == true && $declaration_specifiers.t != null){
	      	  		String name = $simple_declaration::inf.getName();
	      	  		CpmClass _class = new CpmClass($simple_declaration::tag, 
	  					      name, 
	  					      symbolTable.getCurrentNamespace(),
	  					      symbolTable.getCurrentAccess(),
	  					      false);
	  			_class.setLineAndPos($simple_declaration::inf.getLine(),
	  					     $simple_declaration::inf.getPos());
	  			this.insertClass(name, _class);
	      	  	}
	      	  	else{
		      	  	if($declaration_specifiers.error != null){
		      	  		this.yield_error($declaration_specifiers.error, 
			      	  		    fixLine($declaration_specifiers.start),
			      	  		    $declaration_specifiers.start.getCharPositionInLine());
		      	  	}
		      	  	else if($simple_declaration::isEnumDef == false){
		      	  		this.yield_error("error: declaration does not declare anything", 
		      	  			    fixLine($declaration_specifiers.start),
		      	  		    	    $declaration_specifiers.start.getCharPositionInLine());
		      	  	}
		      	  	//else{
		      	  	//	Token declSpecTok = $declaration_specifiers.start;
		      	  		
		      	  	//}
	      	  	}
	      	  }
	      	  else{ 
	      	  	if($declaration_specifiers.hasQuals){
	      	  		yield_error("error: qualifiers can only be specified for objects and functions",
	      	  			    fixLine($declaration_specifiers.start),
	      	  			    $declaration_specifiers.start.getCharPositionInLine());
	      	  	}
	      	  	
	      	  	if($simple_declaration::isEnumDef == true){
	      	  	
	      	  	}
	      	  }
	      }
	  }
	  ;
	
declaration_specifiers returns [Type t, boolean isFwdDecl, boolean hasQuals, String error, String init_decl_err, InClassDeclSpec class_specs, boolean isEnum]
scope Type_Spec;
scope cv_qual;
scope storage_class_spec;
scope function_spec;
@init{
	Type_Spec_at_init();
	cv_qual_at_init();
	storage_class_spec_at_init();
	function_spec_at_init();
	$t = null;
        $error = null;
        $isFwdDecl = false;
	$hasQuals = false;
	$class_specs = null;
}
	:   (    storage_class_specifier {$hasQuals = true;}
        	|   type_qualifier {$hasQuals = true;}
        	|   type_specifier
        	|   function_specifier
            )+
             {
             	Type_Spec_scope type_specs = get_Type_Spec_scope();
             	cv_qual_scope cv_quals = get_cv_qual_scope();
             	function_spec_scope fun_specs = get_function_spec_scope();
             	storage_class_spec_scope storage_specs = get_storage_class_spec();
             	boolean isConst = cv_quals.constCount != 0 ? true : false,
             		isVolatile = cv_quals.volatileCount != 0 ? true : false;
             	
             	$class_specs = new InClassDeclSpec(fun_specs.virtualCount != 0 ? true : false,
             					   fun_specs.explicitCount != 0 ? true : false,
             					   storage_specs.staticCount != 0 ? true : false );
                             	
             	//count for data types in declarations specifiers
             	int countTypes = 0;
             	for(boolean t : type_specs.type) if(t == true) ++countTypes;
             	if(countTypes > 1){	//multiple data types
             		$error = "error: two or more data types in declaration";
             		$init_decl_err = " of";
             	}
             	else{
             		//declaration secifiers is for primitive type
             		if(type_specs.type[0] == true){
             			try{
             				$t = type_specs.counters.checkSpecForPrimitives(isConst, isVolatile);
             			}
             			catch(DeclSpecifierError ex){	
             				//erro in declaration specs for a primitive type
             				$error = ex.error;
             				$init_decl_err = ex.init_delc_list_err;
             			}
             		}
             		//declaration specifiers for user defined type
             		else if(type_specs.type[1] == true){
             			if(type_specs.userDefinedCount > 1){
             				$error = "error: two or more data types in declaration";
             				$init_decl_err = " of";
             			}
             			else{
             				if(type_specs.error_inUserDefined == false && type_specs.named_t != null){
             					$t = new UserDefinedType(type_specs.named_t, isConst, isVolatile);
             					$isFwdDecl = type_specs.isForwardDeclaration;
             				}
             			}
             		}
             		//other cases
             	}

             }
	;
	//catch [EarlyExitException e]{
	//	if(this.pending_undeclared_err != null) throw e;
	//}declarator

	
	
function_specifier
	: virt = 'virtual'
	  {
	  	$function_spec::virtualCount++;
	  	if(this.symbolTable.isCurrentNamespaceClass() == false){
	  		this.yield_error("error: 'virtual' outside class declaration", this.fixLine($virt), $virt.getCharPositionInLine());
	  	}
	  }
	  { virtual_count_error() == true }?
	| 'explicit'
	  {
	  	$function_spec::explicitCount++;
	  }
	  { explicit_count_error() == true }?
	;
	
//class_init_declarator_list[String error, Type data_type, InClassDeclSpec class_specs]
//@init{
//	this.normal_mode = true;
//}
//	: init_declarator_list[$error, $data_type, $class_specs]?
//	;

init_declarator_list [String error, Type data_type, InClassDeclSpec class_specs] returns [boolean newTypeInRv]
scope{
	boolean first;
	boolean newTinRv;
}
@init{
	$init_declarator_list::first = true;
	$init_declarator_list::newTinRv = false;
}
	: init_declarator [$error, $data_type, $class_specs] { $init_declarator_list::first = false; } 
	  (',' init_declarator[$error, $data_type, $class_specs])*
	  {
	  	$newTypeInRv = $init_declarator_list::newTinRv;
	  }
	;

init_declarator [String error, Type data_type, InClassDeclSpec class_specs] 
scope declarator_strings;
scope decl_infered;
scope decl_id_info;
@init{
	$declarator_strings::dir_decl_identifier = null;
	$declarator_strings::dir_decl_error = $error;
	$decl_infered::declarator = null;
	
}
	: declarator { not_null_decl_id($declarator_strings::dir_decl_identifier, $declarator_strings::dir_decl_error, $declarator.start) }? 
	  ('=' initializer)?
	  {	//todo: error for typedef with initializer
	  	if($declarator_strings::dir_decl_identifier != null){
	  		DeclaratorInferedType decl_inf_t = $decl_infered::declarator;
		  	if($data_type != null){
			  	String declarator_id = $declarator_strings::dir_decl_identifier;
			  	int id_line = $decl_id_info::line;
			  	int id_pos = $decl_id_info::pos;
			  	if(decl_inf_t == null) {
			  		if($function_definition.size() == 0) System.out.println($data_type.toString(declarator_id));
			  		if($declaration.size() > 0 && $declaration::isTypedef == true){
			  			this.insertSynonym(declarator_id, $data_type, id_line, id_pos, $class_specs);
			  		}
			  		else{
		  				if($function_definition.size() == 0){
		  					this.insertField(declarator_id, $data_type, id_line, id_pos, $class_specs);
		  				}
			  		}
			  	}
			  	else{
			  		boolean err_inDeclarator = false;
			  		if(decl_inf_t.p_pend != null){
			  			decl_inf_t.p_pend.setPointsTo($data_type);
			  		}
			  		else if(decl_inf_t.m_pend != null){
			  			decl_inf_t.m_pend.getSignature().setReturnValue($data_type);
			  		}
			  		else if(decl_inf_t.ar_pend != null){
			  			decl_inf_t.ar_pend.setType($data_type);
			  		}
			  		else err_inDeclarator = true;
			  		
			  		if(err_inDeclarator == false){
				  		if(decl_inf_t.p_rv != null){
				  			//System.out.println(declarator_id);
				  			System.out.println(decl_inf_t.p_rv.toString(declarator_id));
				  			if($declaration.size() > 0 && $declaration::isTypedef == true){
					  			this.insertSynonym(declarator_id, decl_inf_t.p_rv, id_line, id_pos, $class_specs);
					  		}
					  		else{
				  				if($function_definition.size() == 0){
				  					this.insertField(declarator_id, decl_inf_t.p_rv, id_line, id_pos, $class_specs);
				  				}
					  		}
				  		}
				  		else if(decl_inf_t.m_rv != null){
				  			System.out.println(decl_inf_t.m_rv.toString(declarator_id));
				  			if(($struct_union_or_class_definition.size() > 0 && $class_declaration_list.size() == 0) ||
				  			    $extern_class_definition.size() > 0 ||
				  			   ($simple_declaration.size() > 0 && $simple_declaration::isEnumDef == true) ){
				  			   
				  			   	$init_declarator_list::newTinRv = true;
				  			   	Token declaratorTok = $declarator.start;
				  				this.yield_error("error: new types may not be defined in a return type",
				  						 this.fixLine(declaratorTok),
				  						 declaratorTok.getCharPositionInLine());

				  				if($simple_declaration::isEnumDef == true){
				  					this.yield_error("note: perhaps a semicolon is missing after the definition of '" + 
				  							  $simple_declaration::enumId + "'",
		      	  				 			 	this.fixLine(declaratorTok),
		      	  				 				declaratorTok.getCharPositionInLine());
				  				}
				  			}
				  			else{
					  			if($declaration.size() > 0 && $declaration::isTypedef == true){
						  			this.insertSynonym(declarator_id, decl_inf_t.m_rv, id_line, id_pos, $class_specs);
						  		}
						  		else{
					  				//if(this.symbolTable.isCurrentNamespaceClass() == true){
					  				if($function_definition.size() > 0){
					  					decl_inf_t.m_rv.setIsDefined();
					  					$function_definition::methods_type = decl_inf_t.m_rv;
					  				}
					  				this.insertMethod(declarator_id, decl_inf_t.m_rv, id_line, id_pos, $class_specs);
						  		}
					  		}
				  			
				  		}
				  		else if(decl_inf_t.ar_rv != null){
				  			CpmArray ar = decl_inf_t.ar_rv;
				  			System.out.println(ar.toString(declarator_id));
				  			if($declaration.size() > 0 && $declaration::isTypedef == true){
					  			this.insertSynonym(declarator_id, ar, id_line, id_pos, $class_specs);
					  		}
					  		else{
				  				if($function_definition.size() == 0){
				  					this.insertField(declarator_id, ar, id_line, id_pos, $class_specs);
				  				}
					  		}
				  		}
			  		}
			  	}
		  	}
		  	else if($declarator_strings::dir_decl_error == null && decl_inf_t != null && decl_inf_t.m_pend != null){
		  		this.yield_error("error: C+- forbids declaration of '" + $declarator_strings::dir_decl_identifier + "' with no type",
		  				 this.fixLine($declarator.start),
		  				 $declarator.start.getCharPositionInLine());
		  	}
	  	}
	  }
	;
	
storage_class_specifier
	: 'extern'
	  {
	  	$storage_class_spec::externCount++;
	  }
	  {storage_class_specs_error() == true}?
	| 'static'
	  {
	  	$storage_class_spec::staticCount++;
	  }
	  {storage_class_specs_error() == true}?
	| 'auto'
	  {
	  	$storage_class_spec::autoCount++;
	  }
	  {storage_class_specs_error() == true}?
	| 'register'
	  {
	  	$storage_class_spec::registerCount++;
	  }
	  {storage_class_specs_error() == true}?
	;
	
type_specifier
	: 'void'
	  {
	     $Type_Spec::type[0] = true;
	     $Type_Spec::counters.voidCount++;
	  }
	| 'char'
	  {
	     $Type_Spec::type[0] = true;
	     $Type_Spec::counters.charCount++;
	  }
	| 'short'
	  {
	     $Type_Spec::type[0] = true;
	     $Type_Spec::counters.shortCount++;
	  }
	  {short_count_error() == true}?
	| 'int'
	  {
	     $Type_Spec::type[0] = true;
	     $Type_Spec::counters.intCount++;
	  }
	| 'long'
	  {
	     $Type_Spec::type[0] = true;
	     $Type_Spec::counters.longCount++;
	  }
	| 'float'
	  {
	     $Type_Spec::type[0] = true;
	     $Type_Spec::counters.floatCount++;
	  }
	| 'double'
	  {
	     $Type_Spec::type[0] = true;
	     $Type_Spec::counters.doubleCount++;
	  }
	| 'bool'
	  {
	     $Type_Spec::type[0] = true;
	     $Type_Spec::counters.boolCount++;
	  }
	| 'signed'		//this is the deafault, isn't it ?
	  {
	     $Type_Spec::type[0] = true;
	     $Type_Spec::counters.signedCount++;
	  }
	  {signed_count_error() == true}?
	| 'unsigned'
	  {
	     $Type_Spec::type[0] = true;
	     $Type_Spec::counters.unsignedCount++;
	  }
	  {unsigned_count_error() == true}?
	| struct_union_or_class_specifier
	| nested_name_id
	  { $Type_Spec::type[1] = true;
	    $Type_Spec::userDefinedCount++;

	    $Type_Spec::named_t = this.getNamedType($nested_name_id.names_chain,
	    		      			    $nested_name_id.explicitGlobalScope,
	    		      			    $nested_name_id.containsTemplate,
	    		      			    $nested_name_id.templateArgs);

	    //$Type_Spec::named_t = cached_named_t;
	  }
	  /*
	   * Also check if the nested_name_id is any other kind of symbol ...
	   */
	  {  this.normal_mode == false ||
	    (isValidNamedType($nested_name_id.names_chain,
	    		      $nested_name_id.explicitGlobalScope) == true)}?
	| enum_specifier
	;
	catch[FailedPredicateException ex]{
		//System.out.println("Here");
	}

	
nested_name_id returns [ArrayList<SymbolTable.NestedNameInfo> names_chain, 
			boolean explicitGlobalScope, boolean containsTemplate,
			List<List<Type>> templateArgs]
options{k = 3;}
scope{
  ArrayList<SymbolTable.NestedNameInfo> names;
  boolean isTemplateId;
  List<List<Type>> arguments;
}
@init{
  $nested_name_id::names = new ArrayList<SymbolTable.NestedNameInfo>();
  $nested_name_id::isTemplateId = false;
  $nested_name_id::arguments = new ArrayList<List<Type>> ();
  $explicitGlobalScope = input.LT(1).getText().equals("::") ? true : false;
  $names_chain = $nested_name_id::names;
}
@after{
	$templateArgs = $nested_name_id::arguments;
	$containsTemplate = $nested_name_id::isTemplateId;
}
	: '::'? id scope_resolution*
	;
	
scope_resolution
	: '::' id
	;
	
id
  : template_id
  | name_id
  ;

name_id
@init{
  Token id = input.LT(1);
  $nested_name_id::names.add(new SymbolTable.NestedNameInfo(id.getText(), this.fixLine(id), id.getCharPositionInLine(), false));
}
    : IDENTIFIER
    ;

template_id
scope{
	List<Type> template_arguments;
}
@init{
  Token id = input.LT(1);
  SymbolTable.NestedNameInfo inf = new SymbolTable.NestedNameInfo(id.getText(), this.fixLine(id), id.getCharPositionInLine(), true);
  
  if($nested_name_id::names.indexOf(inf) != $nested_name_id::names.size() - 1)
  	$nested_name_id::names.add(inf);
}
@after{
  $nested_name_id::isTemplateId = true;
  $nested_name_id::arguments.add($template_id::template_arguments);
}
	: 
	  { 
	    $template_id::template_arguments = new ArrayList<Type> (); 
	  }
	  IDENTIFIER '<' template_argument_list '>'
	  {
	  	/*if(this.pending_undeclared_err != null){
	  		Token t = $IDENTIFIER;
	  		int line = this.fixLine(t);
	  		int pos = t.getCharPositionInLine();
	  		this.yield_error(this.pending_undeclared_err, line, pos);
	  	}*/
	  }
	;

template_argument_list
	: template_argument ',' template_argument_list
	| template_argument
	;

template_argument
	: type_name["template argument"]
	  {
	    $template_id::template_arguments.add($type_name.tp);
	  }
	;

struct_union_or_class_specifier
	: struct_union_or_class nested_name_id
	  {
	  	TypeDefinition named_t = null;
	  	try{
	  		$Type_Spec::type[1] = true;
	  		$Type_Spec::userDefinedCount++;
	  		named_t = symbolTable.getNamedTypeFromNestedNameId($nested_name_id.names_chain, $nested_name_id.explicitGlobalScope, true, false);
	  		if(named_t == null){
	  			SymbolTable.NestedNameInfo info = $nested_name_id.names_chain.get(0);
	  			String name = info.getName();
	  			int line = info.getLine();
	  			int pos = info.getPos();
	  			$Type_Spec::isForwardDeclaration = true; 
	  			CpmClass _class = new CpmClass($struct_union_or_class.start.getText(), 
	  					      name, 
	  					      symbolTable.getCurrentNamespace(),
	  					      symbolTable.getCurrentAccess(),
	  					      false);
	  			_class.setLineAndPos(line, pos);
	  			$Type_Spec::named_t = _class;
	  			this.insertClass(name, _class);
	  		}
	  		else if(named_t instanceof SynonymType){
	  			Token tag = $struct_union_or_class.start;
	  			this.yield_error("error: using typedef or enum name '" + named_t.getFullName() + "' after '" + tag.getText() + "'",
	  					  this.fixLine(tag),
	  					  tag.getCharPositionInLine());
	  			$Type_Spec::named_t = null;
	  		}
	  		else{
	  			$Type_Spec::named_t = named_t;
	  		}
	  		
	  	}
	  	catch(AccessSpecViolation access_viol){
	  		yield_error(access_viol.getMessage(), false);
	  		yield_error(access_viol.getContextError(), true);
	  	}
	  	catch(AmbiguousReference ambiguous){
	  		if($nested_name_id.names_chain.size() == 1){
	  			SymbolTable.NestedNameInfo info = $nested_name_id.names_chain.get(0);
	  			String name = info.getName();
	  			int line = info.getLine();
	  			int pos = info.getPos();
	  			$Type_Spec::isForwardDeclaration = true;
	  			CpmClass _class = new CpmClass($struct_union_or_class.start.getText(), 
	  							   name, 
	  					      		   symbolTable.getCurrentNamespace(),
	  					      		   symbolTable.getCurrentAccess(),
	  					      		   false);
	  			_class.setLineAndPos(line, pos);
	  			$Type_Spec::named_t = _class;
	  			this.insertClass(name, _class);
	  		}
	  		else{
		  		yield_error(ambiguous.getRefError(), true);
		  		System.err.print(ambiguous.getMessage());
		  		yield_error(ambiguous.getLastLine(), true);
	  		}
	  	}
	  	catch(NotDeclared nodeclared){
  			yield_error(nodeclared.getMessage(), true);
	  	}
	  	catch(InvalidScopeResolution invalid){
	  		yield_error(invalid.getMessage(), true);
	  	}
	  	catch(DoesNotNameType _){
	  		//not possible
	  	}
	  	
	  	if($Type_Spec::named_t == null){
	  		$Type_Spec::error_inUserDefined = true;
	  	}
	  	else{
	  		if($simple_declaration.size() > 0){
		  		if($nested_name_id.names_chain.size() == 1 && $Type_Spec::named_t.getParentNamespace() != this.symbolTable.getCurrentNamespace()) {
		  			$simple_declaration::possible_fwd_decl = true;
		  			$simple_declaration::inf = $nested_name_id.names_chain.get(0);
		  			$simple_declaration::tag = $struct_union_or_class.start.getText();
		  		}
		  		else{
		  			check_tags($struct_union_or_class.start.getText(), 
		  				   $Type_Spec::named_t,
		  				   this.fixLine($struct_union_or_class.start),
		  				   $struct_union_or_class.start.getCharPositionInLine());
		  		}
		  	}
	  	}
	  }
	;

struct_union_or_class_definition
scope{
	UserDefinedType t;
}
scope collect_base_classes;
scope normal_mode_fail_level;
@init{
	$struct_union_or_class_definition::t = null;
	$normal_mode_fail_level::failed = false;
}
	: struct_union_or_class IDENTIFIER (':' { $collect_base_classes::superClasses = new ArrayList<CpmClass>(); } base_classes = base_class_list)?
	  {
	  	CpmClass _class = null;
	  	String name = $IDENTIFIER.text;
	  	String tag = $struct_union_or_class.start.getText();
	  	if(this.inStlFile == false){
		  	if($base_classes.tree == null){
		  		_class = new CpmClass(tag, name, symbolTable.getCurrentNamespace(), symbolTable.getCurrentAccess(), true);
		  	}
		  	else{
		  		_class = new CpmClass(tag, name, symbolTable.getCurrentNamespace(), $collect_base_classes::superClasses, symbolTable.getCurrentAccess());
		  	}
	  	}
	  	else{
	  		_class = StlContainer.createGenericContainer($IDENTIFIER.text, this.symbolTable.getCurrentNamespace());
	  	}
	  	$struct_union_or_class_definition::t = new UserDefinedType(_class, false, false);
	  	_class.setLineAndPos(this.fixLine($IDENTIFIER), $IDENTIFIER.pos);
	  	_class.setFileName(this.preproc.getCurrentFileName());
	  	CpmClass current_class = this.insertClass(name, _class);
	  	if(current_class != null){
		  	this.symbolTable.setCurrentScope(_class);
		  	if(tag.equals("struct") == true || tag.equals("union") == true){
		  		this.symbolTable.setCurrentAccess(CpmClass.AccessSpecifier.Public);
		  	}
		  	else {
		  		this.symbolTable.setCurrentAccess(CpmClass.AccessSpecifier.Private);
		  	}
	  	}
	  	else{
	  		this.normal_mode = false;
	  		$normal_mode_fail_level::failed = true;
	  	}
	  }
	   // todo : init_declarator_list parameters
  	   '{' class_declaration_list '}' 
  	  {
  	  	this.symbolTable.endScope();
  	  }
  	  init_declarator_list[null, $struct_union_or_class_definition::t, new InClassDeclSpec(false, false, false)]? 
  	  {
  	  	if($init_declarator_list.tree != null && $init_declarator_list.newTypeInRv == true){
  	  		
  	  		Token idTok = $IDENTIFIER;
  	  		this.yield_error("note: perhaps a semicolon is missing after the definition of '" + idTok.getText() + "'",
  	  				 this.fixLine(idTok),
  	  				 idTok.getCharPositionInLine());
  	  	}
  	  }
  	  turn_on_normal_mode
	;
	
extern_class_definition
scope{
	UserDefinedType t;
}
scope collect_base_classes;
scope normal_mode_fail_level;
@init{
	$extern_class_definition::t = null;
	$normal_mode_fail_level::failed = false;
}
	: struct_union_or_class nested_name_id
	  {
	  	if($nested_name_id.containsTemplate == true){
	  		Token nameTok = $nested_name_id.start;
	  		this.yield_error("error: invalid class name (contains template class)",
	  				 this.fixLine(nameTok),
	  				 nameTok.getCharPositionInLine());
	  	}
	  }
	  (':' { $collect_base_classes::superClasses = new ArrayList<CpmClass>(); } base_classes = base_class_list)?
	  {
	  	TypeDefinition t = null;
	  	ArrayList<SymbolTable.NestedNameInfo> chain = $nested_name_id.names_chain;
	  	boolean explicitGlobalScope = $nested_name_id.explicitGlobalScope;
	  	int line = this.fixLine($nested_name_id.start);
	  	int pos = $nested_name_id.start.getCharPositionInLine();
	  	if(explicitGlobalScope == true){
	  		this.yield_error("error: global qualification of class name is invalid in external class definition", line, pos);
	  	}
	  	else{
			try{
				t = symbolTable.getNamedTypeFromNestedNameId(chain, false, false, true);
			}
			catch(Exception _){
				this.yield_error("error: qualified name does not name a class", line, pos);
			}
		}
		CpmClass _class = null;
		if(t != null){
			if(t instanceof CpmClass){
				_class = (CpmClass) t;
				DefinesNamespace current = this.symbolTable.getCurrentNamespace();
				if(_class.isEnclosedInNamespace(current) == true){
					if(_class.isComplete() == true){
						this.yield_error("error: redefinition of '" + _class + "'", line, pos);
						this.yield_error(_class.getFileName() + " line " + _class.getLine() + ":" + _class.getPosition() 
										      + " error: previous definition of '" + _class + "'", false);
					}
					else{
						String tag = $struct_union_or_class.start.getText();
						if(this.check_tags(tag, _class, 
								   this.fixLine($struct_union_or_class.start),
								   $struct_union_or_class.start.getCharPositionInLine()) == true){

							_class.setIsComplete(true);
							_class.setFileName(this.preproc.getCurrentFileName());
							_class.setLineAndPos(line, pos);
							_class.setTag(tag);
							this.symbolTable.setCurrentScope(_class);
							CpmClass.AccessSpecifier acc = null;
							if((acc = this.symbolTable.getCurrentAccess()) != null
							    && acc != _class.getAccess()){
							    
							    this.yield_error("error: '" + _class + "' redeclared with different access", line, pos);
							}
							if($base_classes.tree != null){
								_class.visibleTypesThroughSuperClasses($collect_base_classes::superClasses);
							}
							$extern_class_definition::t = new UserDefinedType(_class, false, false);
							if(tag.equals("struct") == true || tag.equals("union") == true){
						  		this.symbolTable.setCurrentAccess(CpmClass.AccessSpecifier.Public);
						  	}
						  	else {
						  		this.symbolTable.setCurrentAccess(CpmClass.AccessSpecifier.Private);
						  	}
					  	}
					  	else{
					  		_class = null;
					  	}
					}
				}
				else{
					this.yield_error("error: declaration of '" + _class + "' in '" + current + "' which does not enclose '" 
							 + _class.getParentNamespace() + "'",
							 line, pos);
					_class = null;
				}
			}
			else{
				_class = null;
				this.yield_error("error: qualified name does not name a class", line, pos);
			}
		}
		
		if(_class == null){
			this.normal_mode = false;
			$normal_mode_fail_level::failed = true;
		}
	  }
	 '{' class_declaration_list '}' 
	  {
  	  	this.symbolTable.endScope();
  	  }
  	  init_declarator_list[null, $extern_class_definition::t, new InClassDeclSpec(false, false, false)]? 
  	  {
  	  	if($init_declarator_list.tree != null && $init_declarator_list.newTypeInRv == true){
  	  		
  	  		Token idTok = $nested_name_id.stop;
  	  		this.yield_error("note: perhaps a semicolon is missing after the definition of '" + idTok.getText() + "'",
  	  				 this.fixLine(idTok),
  	  				 idTok.getCharPositionInLine());
  	  	}
  	  }
  	  turn_on_normal_mode
	;
	
turn_on_normal_mode
@init{
	if($normal_mode_fail_level::failed == true) this.normal_mode = true;
}
	:
	;

base_class_list
options{ k=3; }
	: 'public' nested_name_id
	 {
	 	int line = this.fixLine($nested_name_id.stop);
	 	int pos = $nested_name_id.stop.getCharPositionInLine() + $nested_name_id.text.length();
	 	try{
	 		CpmClass base = isValidBaseClass($nested_name_id.names_chain, 
	 						 $nested_name_id.explicitGlobalScope,
	 						 ',');
	 		if(base != null){
		 		if(base.isComplete() == false){
		 			this.yield_error("error: invalid use of incomplete type '" + base + "'", line, pos);
		 			this.yield_error("error: forward declaration of '" + base + "'", base.getLine(), base.getPosition());
		 		}
		 		else if(((DefinesNamespace) base) == this.symbolTable.getCurrentNamespace()){
		 			this.yield_error("error: invalid use of incomplete type '" + base + "'", line, pos);
		 			this.yield_error("error: forward declaration of '" + base + "'", base.getLine(), base.getPosition());
		 		}
		 		else if($collect_base_classes::superClasses.contains(base) == true){
		 			this.yield_error("error: duplicate base type '" + base + "' invalid", line, pos);
		 		}
		 		else{
		 			$collect_base_classes::superClasses.add(base);
		 		}
	 		}
	 	}
	 	catch(BaseClassCVQual quals){
	 		this.yield_error(quals.getMessage(), line, pos);
	 	}
	 	catch(Exception ex){
	 		this.yield_error(ex.getMessage(), line, pos);
	 	}
	 
	 }
	 ',' base_class_list
	| 'public' nested_name_id
	  {
	 	int line = this.fixLine($nested_name_id.stop);
	 	int pos = $nested_name_id.stop.getCharPositionInLine()  + $nested_name_id.text.length();
	 	try{
	 		CpmClass base = isValidBaseClass($nested_name_id.names_chain, 
	 						 $nested_name_id.explicitGlobalScope, 
	 						 '{');
	 		if(base != null){
		 		if(base.isComplete() == false){
		 			this.yield_error("error: invalid use of incomplete type '" + base + "'", line, pos);
		 			this.yield_error("error: forward declaration of '" + base + "'", base.getLine(), base.getPosition());
		 		}
		 		else if(((DefinesNamespace) base) == this.symbolTable.getCurrentNamespace()){
		 			this.yield_error("error: invalid use of incomplete type '" + base + "'", line, pos);
		 			this.yield_error("error: forward declaration of '" + base + "'", base.getLine(), base.getPosition());
		 		}
		 		else if($collect_base_classes::superClasses.contains(base) == true){
		 			this.yield_error("duplicate base type '" + base + "' invalid", line, pos);
		 		}
		 		else{
		 			$collect_base_classes::superClasses.add(base);
		 		}
	 		}
	 	}
	 	catch(BaseClassCVQual quals){
	 		this.yield_error(quals.getMessage(), line, pos);
	 	}
	 	catch(Exception ex){
	 		this.yield_error(ex.getMessage(), line, pos);
	 	}
	 
	 }
	;	
    
struct_union_or_class
	: 'struct'
	| 'union'
	| 'class'
	;
	
access_specifier
	: 'private'   { this.symbolTable.setCurrentAccess(CpmClass.AccessSpecifier.Private); }
	| 'protected' { this.symbolTable.setCurrentAccess(CpmClass.AccessSpecifier.Protected); }
	| 'public'    { this.symbolTable.setCurrentAccess(CpmClass.AccessSpecifier.Public); }
	;

class_declaration_list
scope{
	boolean declList;
}
	: class_content_element*
	;
	
class_content_element
	: access_specifier ':'
	| (declaration_specifiers? declarator '{') => function_definition 
	| in_class_declaration
	;
	
constructor
	: construcctor_head ';'
	| construcctor_head 
	  {$construcctor_head.m.setIsDefined();} 
	  compound_statement
	;
	
construcctor_head returns [Method m]
scope parameters_id;
@init{
	$m = null;
	$parameters_id::parameters_ids = null;
}
	: className '(' parameter_type_list? ')'
	  {
	     try{
	        ArrayList<Type> param = null;
	        boolean hasVarArgs = false;
	        Token des_id = $className.start;
	        if($parameter_type_list.tree != null){
	     	    param = $parameter_type_list.params.params;
	     	    hasVarArgs = $parameter_type_list.params.hasVarargs;
	        } 
	     
	     	Method m1 = new Method(null, param, this.symbolTable.getCurrentNamespace(), false, false, false, false, hasVarArgs);
	     	$m = m1;
	     	this.symbolTable.insertConstructor($m, this.fixLine(des_id), des_id.getCharPositionInLine());
	     }
	     catch(CannotBeOverloaded cBeoverld){
                	this.yield_error(cBeoverld.getMessage(), true);
                	this.yield_error(cBeoverld.getFinalError(), false);
             }
	  }
	;
	
destructor
	: destructor_head ';' 
	| destructor_head
	  {$destructor_head.m.setIsDefined();}
	  compound_statement
	;
	
destructor_head returns [Method m]
@init{
	$m = null;
}
	: '~'className '(' parameter_type_list? ')'
	{
	     try{
		     Token des_id = $className.start;
		     if($parameter_type_list.tree != null){
		     	this.yield_error("error: destructors may not have parameters", this.fixLine(des_id), des_id.getCharPositionInLine());
		     }
		     else{
		        /*
		         * cast cannot fail because of the semantic predicate in the className rule
		         */
		     	CpmClass _class = (CpmClass) this.symbolTable.getCurrentNamespace();
		     	Method m1 = new Method(null, null, _class, false, false, false, false, false);
			$m = m1;
	     	     	_class.insertDestructor($m, this.symbolTable.getCurrentAccess(), this.fixLine(des_id), des_id.getCharPositionInLine());
	
	     	     }
	     }
	     catch(CannotBeOverloaded cBeoverld){
               	this.yield_error(cBeoverld.getMessage(), true);
               	this.yield_error(cBeoverld.getFinalError(), false);
             }
	 }
	;

className
	: {normal_mode == false}? IDENTIFIER
	| {(symbolTable.isCurrentNamespaceClass() && input.LT(1).getText().equals(symbolTable.getCurrentNamespace().getName()))}? IDENTIFIER
	;

in_class_declaration
@after {
  this.resetErrorMessageAuxVars();
}
	: constructor
	| destructor
	| declaration
	;
	

specifier_qualifier_list returns [Type t, String error, String init_decl_err]
scope Type_Spec;
scope cv_qual;
@init{
	
	Type_Spec_at_init();
	cv_qual_at_init();
}
	: (   type_qualifier
           |  type_specifier)+
           {
           	Type_Spec_scope type_specs = get_Type_Spec_scope();
             	cv_qual_scope cv_quals = get_cv_qual_scope();
		boolean isConst = cv_quals.constCount != 0 ? true : false,
             		isVolatile = cv_quals.volatileCount != 0 ? true : false;

		int countTypes = 0;
             	for(boolean t : type_specs.type) if(t == true) ++countTypes;
             	if(countTypes > 1){	//multiple data types
             		$error = "error: two or more data types in declaration";
             		$init_decl_err = " of";
             	}
             	else{
             		//declaration secifiers is for primitive type
             		if(type_specs.type[0] == true){
             			try{
             				$t = type_specs.counters.checkSpecForPrimitives(isConst, isVolatile);
             			}
             			catch(DeclSpecifierError ex){	
             				//erro in declaration specs for a primitive type
             				$error = ex.error;
             				$init_decl_err = ex.init_delc_list_err;
             			}
             		}
             		//declaration specifiers for user defined type
             		else if(type_specs.type[1] == true){
             			if(type_specs.userDefinedCount > 1){
             				$error = "error: two or more data types in declaration";
             				$init_decl_err = " of";
             			}
             			else{
             				if(type_specs.error_inUserDefined == false && type_specs.named_t != null){
             					$t = new UserDefinedType(type_specs.named_t, isConst, isVolatile);
             				}
             			}
             		}
             		//other cases
             	}
           }
	;
inclass_function_definition
	: specifier_qualifier_list declarator compound_statement
	;


class_declarator_list
	: class_declarator (',' class_declarator)*
	;

class_declarator
	: declarator (':' constant_expression)?
	| ':' constant_expression
	;

enum_specifier
options {k=3;}
scope{
	UserDefinedType enumeration;
	InClassDeclSpec spec;
}
	: //'enum' '{' enumerator_list '}'
	  'enum' IDENTIFIER 
	  {
	  	$simple_declaration::isEnumDef = true;
	  	$simple_declaration::enumId = $IDENTIFIER.text;
	  	$Type_Spec::type[1] = true;
	  	$Type_Spec::userDefinedCount++;
	  	Token idTok = $IDENTIFIER;
	  	String name = idTok.getText();
	  	int line = this.fixLine(idTok);
	  	int pos = idTok.getCharPositionInLine();
	  	$enum_specifier::spec = new InClassDeclSpec(false, false, false);
	  	SynonymType s_t = new SynonymType(idTok.getText(), this.symbolTable.getCurrentNamespace());
	  	$enum_specifier::enumeration = new UserDefinedType(s_t, true, false);
	  	s_t.setLineAndPos(line, pos);
	  	s_t.setFileName(this.preproc.getCurrentFileName());
		
		try{
			this.symbolTable.insertInnerSyn(name, s_t);
		}
		catch(SameNameAsParentClass sameName){
			this.yield_error(sameName.getMessage(), true);
			$enum_specifier::spec = null;
			$enum_specifier::enumeration = null;
			s_t = null;
		}
                catch(ConflictingDeclaration conflict){
                	this.yield_error(conflict.getMessage(), true);
                	this.yield_error(conflict.getFinalError(), false);
                	$enum_specifier::spec = null;
                	$enum_specifier::enumeration = null;
                	s_t = null;
                }
                catch(Redefinition redef){
                	this.yield_error(redef.getMessage(), true);
                	this.yield_error(redef.getFinalError(), false);
                	$enum_specifier::spec = null;
                	$enum_specifier::enumeration = null;
                	s_t = null;
                }
                catch(DiffrentSymbol diffSymbol){
                	this.yield_error(diffSymbol.getMessage(), true);
                	this.yield_error(diffSymbol.getFinalError(), false);
                	$enum_specifier::spec = null;
                	$enum_specifier::enumeration = null;
                	s_t = null;
                }

                $Type_Spec::named_t = s_t;
	  }
	  '{' enumerator_list '}'
	| t = 'enum' nested_name_id
	  {
	  
	  	TypeDefinition named_t = null;
	  	try{
	  		$Type_Spec::type[1] = true;
	  		$Type_Spec::userDefinedCount++;
	  		named_t = symbolTable.getNamedTypeFromNestedNameId($nested_name_id.names_chain, $nested_name_id.explicitGlobalScope, true, false);
	  		if(named_t == null){
	  			Token namTok = $nested_name_id.stop;
	  			this.yield_error("error: use of enum '" + namTok.getText() + "' without previous declaration",
	  					  this.fixLine(namTok),
	  					  namTok.getCharPositionInLine());
	  		}
	  		else if(named_t instanceof CpmClass){
	  			Token tag = $t;
	  			this.yield_error("error: using '" + named_t.getTag() + " " + named_t.getFullName() + "' after 'enum' tag",
	  					  this.fixLine(tag),
	  					  tag.getCharPositionInLine());
	  			$Type_Spec::named_t = null;
	  		}
	  		else{
	  			$Type_Spec::named_t = named_t;
	  		}
	  		
	  	}
	  	catch(AccessSpecViolation access_viol){
	  		yield_error(access_viol.getMessage(), false);
	  		yield_error(access_viol.getContextError(), true);
	  	}
	  	catch(AmbiguousReference ambiguous){
	  		if($nested_name_id.names_chain.size() == 1){
	  			Token namTok = $nested_name_id.stop;
	  			this.yield_error("error: use of enum '" + namTok.getText() + "' without previous declaration",
	  					  this.fixLine(namTok),
	  					  namTok.getCharPositionInLine());
	  		}
	  		else{
		  		yield_error(ambiguous.getRefError(), true);
		  		System.err.print(ambiguous.getMessage());
		  		yield_error(ambiguous.getLastLine(), true);
	  		}
	  	}
	  	catch(NotDeclared nodeclared){
  			yield_error(nodeclared.getMessage(), true);
	  	}
	  	catch(InvalidScopeResolution invalid){
	  		yield_error(invalid.getMessage(), true);
	  	}
	  	catch(DoesNotNameType _){
	  		//not possible
	  	}
	  	
	  	if($Type_Spec::named_t == null){
	  		$Type_Spec::error_inUserDefined = true;
	  	}
	  }
	;

enumerator_list
	: 
	{
	   if(this.symbolTable.isCurrentNamespaceClass() == true){
  		$enum_specifier::spec.isStatic = true;
  	   }
	}
	enumerator (',' enumerator)*
	;

enumerator
	: IDENTIFIER
	  {
	  	if($enum_specifier::enumeration != null){
		  	Token idTok = $IDENTIFIER;
		  	String name = idTok.getText();
		  	int line = this.fixLine(idTok);
		  	int pos = idTok.getCharPositionInLine();
		  	this.insertField(idTok.getText(), $enum_specifier::enumeration, line, pos, $enum_specifier::spec);
	  	}
	  }
	  ('=' constant_expression)?
	;

type_qualifier
	: 'const'
	  {
	    $cv_qual::constCount++;
	  }
	  {const_count_error() == true}?
	| 'volatile'
	  {
	    $cv_qual::volatileCount++;
	  }
	  {volatile_count_error() == true}?
	;

declarator
scope{
	ArrayList<ptr_cv> pointers;
}
@init{
	$declarator::pointers = null;
}

	: { $declarator::pointers = new ArrayList<ptr_cv>(); } 
	p = pointer[$declarator::pointers]? direct_declarator 
					    { 
					    	if($p.tree != null){
					    		ptr_cv quals = $declarator::pointers.get(0);
					    		Pointer ptr = new Pointer(null, quals.isConst, quals.isVolatile);
					    		Pointer pending = ptr;
					    		for(int i = 1 ; i < $declarator::pointers.size() ; ++i){
					    			quals = $declarator::pointers.get(i);
					    			Pointer temp = new Pointer(null, quals.isConst, quals.isVolatile);
					    			pending.setPointsTo(temp);
					    			pending = temp;
					    		}
						    	if($decl_infered::declarator == null){
						    		$decl_infered::declarator = new DeclaratorInferedType(ptr, pending);
						    	}
						    	else{
						    		$decl_infered::declarator.setPending(ptr, pending);
						    	}
					    	}
					    }
	//| pointer
	;



direct_declarator
	:   ( IDENTIFIER { $declarator_strings::dir_decl_identifier = $IDENTIFIER.text;
			   if($parameter_declaration.size() > 0) $parameter_declaration::p.id = $IDENTIFIER.text;
			   if($decl_id_info.size() > 0){
			   	$decl_id_info::line = this.fixLine($IDENTIFIER);
			   	$decl_id_info::pos = $IDENTIFIER.pos;
			   }
			   if(pending_undeclared_err != null) pending_undeclared_err = null;
			   direct_declarator_error($IDENTIFIER.text, this.fixLine($IDENTIFIER), $IDENTIFIER.pos, $declarator_strings::dir_decl_error); }
			//{
			//if ($declaration.size()>0&& ($declaration::isTypedef)) {
			//	$Symbols::types.add($IDENTIFIER.text);
			//	System.out.println("define type "+$IDENTIFIER.text);
			//}
			//}
		|	'(' dcl = declarator ')'
		)
        	declarator_suffix*
	;
	/*catch [RecognitionException ex]{
		if($init_declarator_list.size() > 0 && $init_declarator_list::first ){
			if($declarator_strings::dir_decl_error == null) throw ex;
			//System.out.println($declarator_strings::dir_decl_error);
			if($declarator_strings::dir_decl_error.equals("error: two or more data types in declaration of") == false) throw ex;
			$init_declarator_list::first = false;
			this.paraphrases.push("error: two or more data types in declaration");
		}
		throw ex;
	}*/

declarator_suffix
scope cv_qual;
@init{
	cv_qual_at_init();
}
	:'[' constant_expression? r_bracket = ']'
	  {
	  	CpmArray ar = new CpmArray(null, 1);
	  	if($decl_infered::declarator == null){
	    		$decl_infered::declarator = new DeclaratorInferedType(ar);
	    	}
	    	else{
	    		try{
	    			$decl_infered::declarator.setPending(ar);
	    		}
	    		catch(Exception ex){
	    			this.yield_error("error: '" + $declarator_strings::dir_decl_identifier + '\'' + " " + ex.getMessage(),
	    					  this.fixLine($r_bracket),
	    					  $r_bracket.getCharPositionInLine());
	    		}
	    	}
	  }
    	|'(' parameter_type_list? r_paren = ')' (type_qualifier+)? pure_virt_method_specifier?
    	  {
    	  	boolean isConst = $cv_qual::constCount != 0 ? true : false, 
    	  		isVolatile = $cv_qual::volatileCount != 0 ? true : false,
    	  		isAbstract = $pure_virt_method_specifier.tree != null ? true : false;
    	  	
    	  	Method m = null;
    	  	ParameterList ps = null;
    	  	if($parameter_type_list.tree != null){
    	  		ps = $parameter_type_list.params;
    	  		if(ps != null){
    	  			/*
    	  			 * virtual = false here because this flag is available in an other level
    	  			 */
    	  			m = new Method(null, ps.params, this.symbolTable.getCurrentNamespace(),
    	  				       false, isAbstract, isConst, isVolatile, ps.hasVarargs);
    	  		}
    	  	}
    	  	else{
    	  		m = new Method(null, null, this.symbolTable.getCurrentNamespace(),
    	  			       false, isAbstract, isConst, isVolatile, false);
    	  	}
    	  	
    	  	if(m != null){
			DeclaratorInferedType d_inf_t = $decl_infered::declarator;
			
			if(d_inf_t == null){
				$decl_infered::declarator = new DeclaratorInferedType(m);
				if($parameter_type_list.tree != null && $parameters_id.size() > 0){
					$parameters_id::parameters_ids = ps.ids;
				}
			}
			else{
				try{
					d_inf_t.setPending(m);
				}
				catch(Exception ex){
					this.yield_error("error: '" + $declarator_strings::dir_decl_identifier + '\'' + " " + ex.getMessage(),
							 this.fixLine($r_paren),
							 $r_paren.getCharPositionInLine());
				}
			}
    	  	}
    	  }
    	//|'(' identifier_list? ')'									//maybe K&R style
    	//|'(' ')' const_method_specifier? pure_virt_method_specifier? == rule3 with parameter_type_list?
	;

pure_virt_method_specifier
	: ('=' '0')
	;

pointer [ArrayList<ptr_cv> pointers]
scope cv_qual;
@init{
	this.cv_qual_at_init();
}
	: '*' type_qualifier+ 
	      {
	      	 $pointers.add(new ptr_cv(($cv_qual::constCount != 0 ? true : false), ($cv_qual::volatileCount != 0 ? true : false)));
	      }
	      pointer[pointers]?
	| '*'
	  {
	  	$pointers.add(new ptr_cv(false, false));
	  }
	  pointer[pointers]
	| '*' { $pointers.add(new ptr_cv(false, false)); }
	;

parameter_type_list returns [ParameterList params]
scope{
	ParameterList p_list;
	boolean error_in_parameters;
}
	: {
	   $parameter_type_list::p_list = new ParameterList();
	   $parameter_type_list::error_in_parameters = false;
	  }
	  parameter_list (','? varargs = '...')? 
	  {
	    if($parameter_type_list::error_in_parameters == true) $params = null;
	    else{
	      $parameter_type_list::p_list.hasVarargs = ($varargs != null) ? true : false;
	      $params = $parameter_type_list::p_list;
	    }
	  }
	  | {
	   	$parameter_type_list::p_list = new ParameterList();
	   	$parameter_type_list::error_in_parameters = false;
	    } 
	    '...' { $parameter_type_list::p_list.hasVarargs = true; 
	    	    $params = $parameter_type_list::p_list;
	    	  }
	;

parameter_list
	: param_decl1 = parameter_declaration
	  //{ this.state.backtracking > 0 || $param_decl1.param != null }?
	  { if($param_decl1.param != null){
	  	$parameter_type_list::p_list.insertParam($param_decl1.param);
	    }
	    else{
	    	$parameter_type_list::error_in_parameters = true;
	    }
	  }
	 (',' param_decl2 = parameter_declaration
	  //{ this.state.backtracking > 0 || $param_decl2.param != null }?
	  { if($param_decl2.param != null){
	  	$parameter_type_list::p_list.insertParam($param_decl2.param);
	    }
	    else{
	    	$parameter_type_list::error_in_parameters = true;
	    }
	  }
	  )*
	;
	catch [FailedPredicateException _]{
		/*
		 * don't show the error message from the predicate
		 * all error messages are being handle inside parameter_declaration rule
		 */
	}

parameter_declaration returns [Param param]
scope{
	Param p;
}
scope declarator_strings;
scope decl_infered;
@init{
	$declarator_strings::dir_decl_identifier = null;
	$declarator_strings::dir_decl_error = null;
	$decl_infered::declarator = null;
}
	: { $parameter_declaration::p = new Param(); }
	  declaration_specifiers
	  {
	  	if($declaration_specifiers.error != null){
	  		$declarator_strings::dir_decl_error = $declaration_specifiers.error + $declaration_specifiers.init_decl_err;
	  	}
	  }
	  (d = declarator | ad = abstract_declarator)?
	  {
	  	Type data_type = $declaration_specifiers.t;
	  	if(data_type != null){
		  	DeclaratorInferedType decl_inf_t = $decl_infered::declarator;
		  	String declarator_id = $declarator_strings::dir_decl_identifier;
		  	if(decl_inf_t == null) {
		  		$parameter_declaration::p.t = data_type;
		  		$param = $parameter_declaration::p;
		  	}
		  	else{
		  		boolean error_in_declarator = false;
		  		if(decl_inf_t.p_pend != null){
		  			decl_inf_t.p_pend.setPointsTo(data_type);
		  		}
		  		else if(decl_inf_t.m_pend != null){
		  			decl_inf_t.m_pend.getSignature().setReturnValue(data_type);
		  		}
		  		else if(decl_inf_t.ar_pend != null){
		  			decl_inf_t.ar_pend.setType(data_type);
		  		}
		  		else{
		  			error_in_declarator = true;
		  		}
		  		
		  		if(error_in_declarator == false){
			  		if(decl_inf_t.p_rv != null){
			  			$parameter_declaration::p.t = decl_inf_t.p_rv;
			  		}
			  		else if(decl_inf_t.m_rv != null){
			  			$parameter_declaration::p.t = new Pointer(decl_inf_t.m_rv, false, false);
			  		}
			  		else if(decl_inf_t.ar_rv != null){
			  			$parameter_declaration::p.t = decl_inf_t.ar_rv;
			  		}
			  		$param = $parameter_declaration::p;
		  		}
		  		else{
		  			$param = null;
		  		}
		  	}
		  }
		  else{
		  	$param = null;
		  	if($d.tree == null && $ad.tree == null){
			  	if($declarator_strings::dir_decl_error != null){
			  		Token end_t = $declaration_specifiers.stop;
			  		int line = this.fixLine(end_t);
			  		int pos = end_t.getCharPositionInLine();
			  		this.yield_error($declarator_strings::dir_decl_error + " 'parameter'", line, pos);
			  	}
		  	}
		  }
	  }
	;

identifier_list
	: IDENTIFIER (',' IDENTIFIER)*
	;

type_name [String id] returns [Type tp]
scope declarator_strings;
scope decl_infered;
@init{
	$declarator_strings::dir_decl_identifier = $id;
	$declarator_strings::dir_decl_error = null;
	$decl_infered::declarator = null;
	$tp = null;
}
	: specifier_qualifier_list
	  {
	  	if($specifier_qualifier_list.error != null)
		  	$declarator_strings::dir_decl_error = $specifier_qualifier_list.error + $specifier_qualifier_list.init_decl_err;
	  }
	  abstract_declarator?
	  {
	  	if($abstract_declarator.tree == null) {
	  		if($declarator_strings::dir_decl_error != null) {
		  		Token last_t = $specifier_qualifier_list.stop;
		  		int line = this.fixLine(last_t);
		  		int pos = last_t.getCharPositionInLine();
		  		this.yield_error($declarator_strings::dir_decl_error, line, pos);
	  		}
	  		else{
	  			$tp =  $specifier_qualifier_list.t;
	  		}
	  	}
	  	else {
	  		Type dataType = $specifier_qualifier_list.t;
	  		DeclaratorInferedType decl_inf_t = $decl_infered::declarator;
	  		if(dataType != null){
			  	if(decl_inf_t == null) {
			  		$tp = dataType;
			  	}
			  	else{
			  		boolean err_inDeclarator = false;
			  		if(decl_inf_t.p_pend != null){
			  			decl_inf_t.p_pend.setPointsTo(dataType);
			  		}
			  		else if(decl_inf_t.m_pend != null){
			  			decl_inf_t.m_pend.getSignature().setReturnValue(dataType);
			  		}
			  		else if(decl_inf_t.ar_pend != null){
			  			decl_inf_t.ar_pend.setType(dataType);
			  		}
			  		else err_inDeclarator = true;
			  		
			  		if(err_inDeclarator == false){
				  		if(decl_inf_t.p_rv != null){
				  			$tp = decl_inf_t.p_rv;
				  		}
				  		else if(decl_inf_t.m_rv != null){
				  			$tp = decl_inf_t.m_rv;
				  		}
				  		else if(decl_inf_t.ar_rv != null){
				  			$tp = decl_inf_t.ar_rv;
				  		}
			  		}
			  	}
	  		}
	  	}
	  }
	;

abstract_declarator
scope{
	ArrayList<ptr_cv> pointers;
}
@init{
	if($declarator_strings::dir_decl_identifier == null) $declarator_strings::dir_decl_identifier = "parameter";
}
	: { 
	    $abstract_declarator::pointers = new ArrayList<ptr_cv>();
	    if($declarator_strings::dir_decl_error != null){
		Token next_tok = this.input.LT(1);
		int line = this.fixLine(next_tok);
		int pos = next_tok.getCharPositionInLine();
		this.yield_error($declarator_strings::dir_decl_error + " '" + $declarator_strings::dir_decl_identifier + "'", line, pos);
	     } 
	  }
	  pointer[$abstract_declarator::pointers]
	  direct_abstract_declarator?
	  {
	  	ptr_cv quals = $abstract_declarator::pointers.get(0);
    		Pointer ptr = new Pointer(null, quals.isConst, quals.isVolatile);
    		Pointer pending = ptr;
    		for(int i = 1 ; i < $abstract_declarator::pointers.size() ; ++i){
    			quals = $abstract_declarator::pointers.get(i);
    			Pointer temp = new Pointer(null, quals.isConst, quals.isVolatile);
    			pending.setPointsTo(temp);
    			pending = temp;
    		}
	    	if($decl_infered::declarator == null){
	    		$decl_infered::declarator = new DeclaratorInferedType(ptr, pending);
	    	}
	    	else{
	    		$decl_infered::declarator.setPending(ptr, pending);
	    	}
	  }
	| direct_abstract_declarator
	;

direct_abstract_declarator
	:	( '(' par_decl = abstract_declarator ')' | decl_suf = declarator_suffix ) decl_suffixes += declarator_suffix*
	;


initializer
	: assignment_expression
	| '{' initializer_list ','? '}'
	;

initializer_list
	: initializer (',' initializer)*
	;

// E x p r e s s i o n s

argument_expression_list
	:   assignment_expression (',' assignment_expression)*
	;

additive_expression
	: (multiplicative_expression) ('+' multiplicative_expression | '-' multiplicative_expression)*
	;

multiplicative_expression
	: (cast_expression) ('*' cast_expression | '/' cast_expression | '%' cast_expression)*
	;

cast_expression
	: '(' type_name["type name"] ')' cast_expression
	| unary_expression
	;

unary_expression
	: postfix_expression
	| '++' unary_expression
	| '--' unary_expression
	| unary_operator cast_expression
	| 'sizeof' '(' type_name["type name"] ')'
	| 'sizeof' unary_expression
	;

postfix_expression
	:   primary_expression
        (   '[' expression ']'
        |   '(' ')'
        |   '(' argument_expression_list ')'
        |   '.' IDENTIFIER
        |   '->' IDENTIFIER
        |   '++'
        |   '--'
        )*
	;

unary_operator
	: '&'
	| '*'
	| '+'
	| '-'
	| '~'
	| '!'
	;

constant
    :   HEX_LITERAL
    |   OCTAL_LITERAL
    |   DECIMAL_LITERAL
    |	CHARACTER_LITERAL
    |	STRING_LITERAL
    |   FLOATING_POINT_LITERAL
    ;
    
primary_expression
	: constant
	| nested_name_id
	| 'this'
	| '(' expression ')'
	;

 
expression
	: assignment_expression (',' assignment_expression)*
	;

constant_expression
	: conditional_expression
		;

assignment_expression
	: lvalue assignment_operator assignment_expression -> ^(assignment_expression lvalue assignment_expression)
	| conditional_expression
	| new_exp
	;
new_exp
	: 'new' nested_name_id ('('argument_expression_list?')')?
	;

	
lvalue
	:	unary_expression
	;

assignment_operator
	: '='
	| '*='
	| '/='
	| '%='
	| '+='
	| '-='
	| '<<='
	| '>>='
	| '&='
	| '^='
	| '|='
	;

conditional_expression
	: logical_or_expression ('?' expression ':' conditional_expression)?
	;

logical_or_expression
	: logical_and_expression ('||' logical_and_expression)*
	;

logical_and_expression
	: inclusive_or_expression ('&&' inclusive_or_expression)*
	;

inclusive_or_expression
	: exclusive_or_expression ('|' exclusive_or_expression)*
	;

exclusive_or_expression
	: and_expression ('^' and_expression)*
	;

and_expression
	: equality_expression ('&' equality_expression)*
	;
equality_expression
	: relational_expression (('=='|'!=') relational_expression)*
	;

relational_expression
	: shift_expression (('<'|'>'|'<='|'>=') shift_expression)*
	;

shift_expression
	: additive_expression (('<<'|'>>') additive_expression)*
	;

// S t a t e m e n t s

statement
	: labeled_statement
	| compound_statement
	| expression_statement
	| selection_statement
	| iteration_statement
	| jump_statement
	;

labeled_statement
	: IDENTIFIER ':' statement
	| 'case' constant_expression ':' statement
	| 'default' ':' statement
	;

compound_statement
	: '{' (declaration | statement)* '}'				//not only at the begining
	;

statement_list
	: statement+
	;

expression_statement
	: ';'
	| expression ';'
	;

selection_statement
	: 'if' '(' expression ')' statement (options {k=1; backtrack=false;}:'else' statement)?
	| 'switch' '(' expression ')' statement
	;

iteration_statement
	: 'while' '(' expression ')' statement
	| 'do' statement 'while' '(' expression ')' ';'
	| 'for' '(' init_for_iteration_stmt expression_statement expression? ')' statement
		;
			
			init_for_iteration_stmt
	: //simple_declaration
	  expression_statement
	;

jump_statement
	: 'goto' IDENTIFIER ';'
	| 'continue' ';'
	| 'break' ';'
	| 'return' ';'
	| 'return' expression ';'
	;
	
//Preprocessor

/*
 * Instead of explicitly put 1,2,3,4 as flags
 * I put DECIMAL_LITERAL lexer rule because 
 * there is obviosly a conflict between these two.
 * And of course in this phase the output would be correct,
 * because it comes from cpp
 */
 
line_marker
scope{
	boolean is_enter;
	boolean is_exit;
	boolean is_stl_header;
}
@init{
	$line_marker::is_enter = false;
	$line_marker::is_exit = false;
	$line_marker::is_stl_header = false;
}
	: h_tag = '#' DECIMAL_LITERAL STRING_LITERAL line_marker_flags? { String file = $STRING_LITERAL.text;
									  file = file.substring(1, file.length() - 1);
									  int baseLine = Integer.parseInt($DECIMAL_LITERAL.text);
									  int preprocLine = $h_tag.line;

									  //ignore preproc useless stuff 
									  if(file.equals("<built-in>") == false && file.equals("<command-line>") == false){
									  
									  	  this.inStlFile = $line_marker::is_stl_header;
									  	  this.stlFile = file;

										  if($line_marker::is_enter == true){
										  	this.preproc.enterIncludedFile(file, 
										  				       baseLine,
										  				       preprocLine,
										  				       this.fixLine($h_tag));
										  }
										  else if($line_marker::is_exit == true){
										  	this.preproc.exitIncludedFile(baseLine, preprocLine);
										  	$line_marker::is_stl_header = false;
										  }
										  else{
										  	this.preproc.enterIncludedFile(file,
										  				       baseLine,
										  				       preprocLine,
										  				       preprocLine);
										  }
									  }
									}
	;

line_marker_flags
	: DECIMAL_LITERAL
	  {
	  	int flag = Integer.parseInt($DECIMAL_LITERAL.text);
	  	if(flag == 1) $line_marker::is_enter = true;
	  	else if(flag == 2) $line_marker::is_exit = true;
	  	else if(flag == 3) $line_marker::is_stl_header = true;
	  }
	  line_marker_flags
	| DECIMAL_LITERAL
	  {
	  	int flag = Integer.parseInt($DECIMAL_LITERAL.text);
	  	if(flag == 1) $line_marker::is_enter = true;
	  	else if(flag == 2) $line_marker::is_exit = true;
	  	else if(flag == 3) $line_marker::is_stl_header = true;
	  }
	;

IDENTIFIER
	:	LETTER (LETTER|'0'..'9')*
	;

fragment
LETTER
	:	'$'
	|	'A'..'Z'
	|	'a'..'z'
	|	'_'
	;

CHARACTER_LITERAL
    :   '\'' ( EscapeSequence | ~('\''|'\\') ) '\''
    ;

STRING_LITERAL
    :  '"' ( EscapeSequence | ~('\\'|'"') )* '"'
    ;



fragment
ZERO 	: '0';
DECIMAL_LITERAL
	: (ZERO | '1'..'9' '0'..'9'*) IntegerTypeSuffix?
	;

OCTAL_LITERAL : '0' ('0'..'7')+ IntegerTypeSuffix?
	      ;

HEX_LITERAL : '0' ('x'|'X') HexDigit+ IntegerTypeSuffix?
	    ;

fragment
HexDigit : ('0'..'9'|'a'..'f'|'A'..'F') ;

fragment
IntegerTypeSuffix
options{greedy = true;}
	:	('u'|'U')? ('l'|'L')
	|	('u'|'U')  ('l'|'L')?
	;

FLOATING_POINT_LITERAL
options{greedy = true;}
    :   ('0'..'9')+ '.' ('0'..'9')* Exponent? FloatTypeSuffix?
    |   '.' ('0'..'9')+ Exponent? FloatTypeSuffix?
    |   ('0'..'9')+ Exponent FloatTypeSuffix?
    |   ('0'..'9')+ Exponent? FloatTypeSuffix
	;

fragment
Exponent : ('e'|'E') ('+'|'-')? ('0'..'9')+ ;

fragment
FloatTypeSuffix : ('f'|'F'|'d'|'D') ;

fragment
EscapeSequence
    :   '\\' ('b'|'t'|'n'|'f'|'r'|'\"'|'\''|'\\')
    |   OctalEscape
    ;

fragment
OctalEscape
    :   '\\' ('0'..'3') ('0'..'7') ('0'..'7')
    |   '\\' ('0'..'7') ('0'..'7')
    |   '\\' ('0'..'7')
    ;

fragment
UnicodeEscape
    :   '\\' 'u' HexDigit HexDigit HexDigit HexDigit
    ;

WS  :  (' '|'\r'|'\t'|'\u000C'|'\n') { $channel=HIDDEN; }
    ;

COMMENT
    :   '/*' ( options {greedy=false;} : . )* '*/' {$channel=HIDDEN;}
    ;

LINE_COMMENT
    : '//' ~('\n'|'\r')* '\r'? '\n' {$channel=HIDDEN;}
    ;


// ignore #line info for now
//LINE_COMMAND 
//    : '#' ~('\n'|'\r')* '\r'? '\n' {$channel=HIDDEN;}
//    ;