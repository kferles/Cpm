grammar Cpm;
options {
    backtrack=true;
    memoize=true;
    k=2;
    output=AST;
}

tokens{
	DECLARATION;
	DECLARATION_LIST;
	LINE_MARKER;
	INDEX;
	CALL;
	OBJ_ACCESS;
	PTR_ACCESS;
	INCR_POSTFIX;
	DECR_POSTFIX;
	INITIALIZER_LIST;
	NESTED_IDENTIFIER;
	RETURN_EXP;
	FOR_STMT;
	FOR_BODY;
	DO_WHILE_STMT;
	DO_WHILE_BODY;
	WHILE_COND;
	WHILE_BODY;
	IF_STMT;
	IF_ELSE_STMT;
	SWITCH_STMT;
	ELSE_PRT;
	COMP_STMT;
	CASE_STMT;
	DEFAULT_STMT;
	CASE_SLCT;
	LINE_MARKER_ENTER;
	LINE_MARKER_EXIT;
	USING_DIRECTIVE;
	TYPE_NAME;
	SPEC_QUAL_LIST;
	NEW_TYPE_ID;
	EXPRESSION_LIST;
	NEW_INITIALIZER;
	CONSTRUCTOR;
	DESTRUCTOR;
	METHOD;
	NAMESPACE;
	STR_UN_CLASS_DEFINITION;
	EXTERN_CLASS_DEFINITION;
	ENUM_DEFINITION;
	ID_EXPRESSION;
	FWD_DECLARATION;
	CLASS_DECLARATION_LIST;
	ENUMERATOR;
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

scope constructorDef{
	boolean isDefinition;
}

scope destructorDef{
	boolean isDefinition;
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
import treeNodes4antlr.*;
}

@parser::members {

	private boolean errorInThisPhase = false;

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
		this.errorInThisPhase = true;
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
			System.err.println(temp.getMessage());
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
	
	private void yield_warning(String warning, int line, int pos){
		String fileName = this.getSourceName();
		warning = fileName + " line " + line + ":" + pos + " " + warning;
		System.err.print(this.preproc.getHeaderError());
		System.err.println(warning);
	}
	
	private void yield_error(String error, boolean need_file_name){
		this.errorInThisPhase = true;
		if(need_file_name){
			String fileName = this.getSourceName();
			error = fileName + " " + error;
		}
		System.err.print(this.preproc.getHeaderError());
		System.err.println(error);
	} 
	
	private void yield_error(String error, int line, int position){
		this.errorInThisPhase = true;
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
			//if(chain.size() > 1){
		  	//	yield_error(access_viol.getMessage(), false);
		  	//	yield_error(access_viol.getContextError(), true);
	  		//}
	  		//else{
	  		this.pending_access_viol = access_viol;
	  		//}

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
		catch(InvalidMethodLocalDeclaration invalidMethDecl){
			this.yield_error(invalidMethDecl.getMessage(), cpm_class.getLine(), cpm_class.getPosition());
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
                catch(InvalidMethodLocalDeclaration invalidMethDecl){
                	this.yield_error(invalidMethDecl.getMessage(), id_line, id_pos);
                }
	}
	
	private Type insertField(String declarator_id, Type t, int id_line, int id_pos, InClassDeclSpec class_specs){
		
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
					return this.symbolTable.insertField(declarator_id, t, class_specs.isStatic, this.preproc.getCurrentFileName(), id_line, id_pos);
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
                
                return null;
	}
	
	private void insertMethod(String declarator_id, Method m, int id_line, int id_pos, InClassDeclSpec class_specs, boolean insideFunctionDef){
	
		try{
			if(class_specs != null && class_specs.isExplicit == true){
				this.yield_error("error: only declarations of constructors can be 'explicit'", id_line, id_pos);
			}
			else{
				m.setVirtual(class_specs != null ? class_specs.isVirtual : false);
				this.symbolTable.insertMethod(declarator_id, m, class_specs != null ? class_specs.isStatic : false,
							      this.preproc.getCurrentFileName(), id_line, id_pos, insideFunctionDef);
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
                catch(InvalidMethodLocalDeclaration invMethodDecl){
                	this.yield_error(invMethodDecl.getMessage(), id_line, id_pos);
                }
	
	}
	
	//end insert into current scope

	boolean normal_mode = true;
	
	//using directive aux methods 
	
	/*
	 * public methods to pass information to next phases...
	 */
	
	public boolean errorsInPhase(){
		return this.errorInThisPhase;
	}
	
	public SymbolTable getSymbolTable(){
		return this.symbolTable;
	}

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
	| ( declaration_specifiers? declarator (':' ctor_initializer)? '{' )=> function_definition
	| declaration
	;

namespace_definition
scope{
	Namespace nmsp;
}
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
	  	
	  	$namespace_definition::nmsp = _namespace;
	  	
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
	   
	   -> ^(NAMESPACE<NamespaceToken>[$namespace_definition::nmsp] external_declaration*)
	;
	
function_definition
scope{
	Method methods_type;
	String identifier;
	boolean isConstructorDefinition;
	boolean isDestructorDefinition;
	MethodDefinition methDef;
}
scope normal_mode_fail_level;
@init{
	$function_definition::methods_type = null;
	$function_definition::identifier = null;
	$function_definition::isConstructorDefinition = false;
	$function_definition::isDestructorDefinition = false;

	$normal_mode_fail_level::failed = false;
	
	this.resetErrorMessageAuxVars();
}
	: {
		MethodDefinition methDef = new MethodDefinition(this.symbolTable.getCurrentNamespace());
		$function_definition::methDef = methDef;
		try{
			this.symbolTable.insertMethDefinition(methDef);
		}
		catch(InvalidMethodLocalDeclaration invalidMethDecl){
			Token nextTok = input.LT(1);
			this.yield_error(invalidMethDecl.getMessage(), this.fixLine(nextTok), nextTok.getCharPositionInLine());
			this.normal_mode = false;
			$normal_mode_fail_level::failed = true;
		}
	  	this.symbolTable.setCurrentScope(methDef);
	  	this.symbolTable.setCurrentAccess(null);
	  }
	  simple_declaration (':' init=ctor_initializer)?  // ANSI style only
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
	  	else{
	  		if($function_definition::isConstructorDefinition == false && $init.tree != null){
	  			Token err_tok = $init.start;
	  			this.yield_error("error: only constructors take member initializers", this.fixLine(err_tok), err_tok.getCharPositionInLine());
	  		}
	  	}
	  }
	  compound_statement turn_on_normal_mode 
	  {
	  	this.symbolTable.endScope();
	  }

	  -> ^(METHOD<MethodToken>[$function_definition::methods_type, $function_definition::methDef, 
	  			   $function_definition::isConstructorDefinition, $function_definition::isDestructorDefinition] 
	  											      ctor_initializer? 
	  											      /*
	  											       * optional in case normal mode is false
	  											       */
	  											      compound_statement?)
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
	: ('typedef'? struct_union_or_class IDENTIFIER ':' 'public') => t='typedef'? { if($t != null) $declaration::isTypedef = true; } struct_union_or_class_definition ';'!
	| ('typedef'? struct_union_or_class IDENTIFIER '{') => t='typedef'? { if($t != null) $declaration::isTypedef = true; } struct_union_or_class_definition ';'!
	| ('typedef'? struct_union_or_class nested_name_id ':' 'public') => t='typedef'? { if($t != null) $declaration::isTypedef = true; } extern_class_definition ';'!
	| ('typedef'? struct_union_or_class nested_name_id '{') => t='typedef'? { if($t != null) $declaration::isTypedef = true; } extern_class_definition ';'!
	| t='typedef'? { if($t != null) $declaration::isTypedef = true; } enum_definition ';'!
	| 'typedef' { $declaration::isTypedef = true; } simple_declaration ';'!
	| simple_declaration ';'!
	| using_directive ';'!
	| line_marker
	;

/*
 * TODO: check if findInnerNamespace must be invoked.
 */
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
	-> ^(USING_DIRECTIVE<UsingDirectiveToken>[$using_directive::finalNamespace])
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
	boolean isFwdDecl;
	SymbolTable.NestedNameInfo inf;
	String tag;
	String enumId;
	String declSpecError;
	Type declSpecT;
	InClassDeclSpec declSpecs;
	boolean noDeclSpecifiers;
}
@init{
	$simple_declaration::possible_fwd_decl = false;
	$simple_declaration::inf = null;
	$simple_declaration::tag = null;
	$simple_declaration::noDeclSpecifiers = false;
}
 	:
	  declaration_specifiers?
	  {
	  	if($declaration_specifiers.tree == null){
	  		$simple_declaration::noDeclSpecifiers = true;
	  	}
	  	$simple_declaration::declSpecError = $declaration_specifiers.error != null ? $declaration_specifiers.error + $declaration_specifiers.init_decl_err : null;
	  	$simple_declaration::declSpecT = $declaration_specifiers.t;
	  	$simple_declaration::declSpecs = $declaration_specifiers.class_specs;
	  }
	  decl_list = init_declarator_list[$simple_declaration::declSpecError,
	  				   $simple_declaration::declSpecT,
	  				   $simple_declaration::declSpecs]?
	  {
	      $simple_declaration::isFwdDecl = $declaration_specifiers.isFwdDecl;
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
	  			$simple_declaration::isFwdDecl = true;
	      	  	}
	      	  	else{
		      	  	if($declaration_specifiers.error != null){
		      	  		this.yield_error($declaration_specifiers.error, 
			      	  		    fixLine($declaration_specifiers.start),
			      	  		    $declaration_specifiers.start.getCharPositionInLine());
		      	  	}
		      	  	else{
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
	      	  }
	      }
	  }
	  -> {$simple_declaration::isFwdDecl && $init_declarator_list.tree == null}? FWD_DECLARATION<FwdDeclarationToken>[$declaration_specifiers.t]
	  -> {$simple_declaration::isFwdDecl && $init_declarator_list.tree != null}? ^(FWD_DECLARATION<FwdDeclarationToken>[$declaration_specifiers.t] init_declarator_list)
	  -> init_declarator_list
	  ;
	
declaration_specifiers returns [Type t, boolean isFwdDecl, boolean hasQuals, String error, String init_decl_err, InClassDeclSpec class_specs]
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
	  
	  -> ^(DECLARATION_LIST init_declarator+)
	;

init_declarator [String error, Type data_type, InClassDeclSpec class_specs] returns [Type declType]
scope{
	boolean isExternDef;
	DefinesNamespace namespace; 
	boolean isDestructor;
	boolean isMethodDecl;
}
scope declarator_strings;
scope decl_infered;
scope decl_id_info;
@init{
	$declarator_strings::dir_decl_identifier = null;
	$declarator_strings::dir_decl_error = $error;
	$decl_infered::declarator = null;
	$init_declarator::isExternDef = false;
	$init_declarator::namespace = null;
	$init_declarator::isDestructor = false;
	$init_declarator::isMethodDecl = false;
}
	: declarator { not_null_decl_id($declarator_strings::dir_decl_identifier, $declarator_strings::dir_decl_error, $declarator.start); } 
	  (  eq = '=' initializer
	   | lpar = '(' argument_expression_list ')' )?
	  {	//todo: error for typedef with initializer && externdef ...
	  	//todo: typedef + extern def

	  	boolean externDef = $init_declarator::isExternDef;
	  	boolean isNameSpEnclosed = false;
	  	boolean resultNotMethod = true;
	  	DefinesNamespace nameSp = $init_declarator::namespace;
		LookupResult res = null;
		String id = $declarator_strings::dir_decl_identifier;
		boolean isNameSpClass = false;
		if(externDef){
	  		DefinesNamespace curr_scope = this.symbolTable.getCurrentNamespace();
	  		
			if(nameSp != null){
				if(nameSp instanceof CpmClass) isNameSpClass = true;
	  			res = nameSp.localLookup(id, curr_scope, false, true);
	  			
	  			DefinesNamespace current;
	  			
	  			if($function_definition.size() > 0)
	  				current = ((MethodDefinition) curr_scope).getDefinedInNamespace();
	  			else
	  				current = curr_scope;
	  			
	  			isNameSpEnclosed = nameSp.isEnclosedInNamespace(current);
	  		}
	  		
		}

	  	$declType = null;
	  	if($declarator_strings::dir_decl_identifier != null){

	  		DeclaratorInferedType decl_inf_t = $decl_infered::declarator;
		  	if($data_type != null 
		  	   ||
		  	   /*possibly defining constructor/destructor outside the class definition*/ 
		  	   (decl_inf_t != null && 
		  	    decl_inf_t.m_pend != null && 
		  	    externDef == true && 
		  	    isNameSpClass &&
		  	    nameSp.getName().equals(id))){

			  	String declarator_id = $declarator_strings::dir_decl_identifier;
			  	int id_line = $decl_id_info::line;
			  	int id_pos = $decl_id_info::pos;
			  	if(decl_inf_t == null) {
			  		$declType = $data_type;
			  		if($declaration.size() > 0 && $declaration::isTypedef == true){
			  			this.insertSynonym(declarator_id, $data_type, id_line, id_pos, $class_specs);
			  		}
			  		else{
		  				if(externDef == false){
		  					$declType = this.insertField(declarator_id, $data_type, id_line, id_pos, $class_specs);
		  				}
			  		}
			  	}
			  	else{
			  		boolean err_inDeclarator = false;
			  		if(decl_inf_t.p_pend != null){
			  			decl_inf_t.p_pend.setPointsTo($data_type);
			  		}
			  		else if(decl_inf_t.m_pend != null){
			  			$init_declarator::isMethodDecl = true;
			  			decl_inf_t.m_pend.getSignature().setReturnValue($data_type);
			  		}
			  		else if(decl_inf_t.ar_pend != null){
			  			decl_inf_t.ar_pend.setType($data_type);
			  		}
			  		else err_inDeclarator = true;
			  		
			  		if(err_inDeclarator == false){
				  		if(decl_inf_t.p_rv != null){
				  			$declType = decl_inf_t.p_rv;
				  			if($declaration.size() > 0 && $declaration::isTypedef == true){
					  			this.insertSynonym(declarator_id, decl_inf_t.p_rv, id_line, id_pos, $class_specs);
					  		}
					  		else{
				  				if(externDef == false){
				  					$declType = this.insertField(declarator_id, decl_inf_t.p_rv, id_line, id_pos, $class_specs);
				  				}
					  		}
				  		}
				  		else if(decl_inf_t.m_rv != null){
				  			resultNotMethod = false;
				  			$declType = decl_inf_t.m_rv;
				  			if(($struct_union_or_class_definition.size() > 0 && $class_declaration_list.size() == 0) ||
				  			    $extern_class_definition.size() > 0 || $enum_definition.size() > 0 ){

				  			   	$init_declarator_list::newTinRv = true;
				  			   	Token declaratorTok = $declarator.start;
				  				this.yield_error("error: new types may not be defined in a return type",
				  						 this.fixLine(declaratorTok),
				  						 declaratorTok.getCharPositionInLine());
				  			}
				  			else{
					  			if($declaration.size() > 0 && $declaration::isTypedef == true){
						  			this.insertSynonym(declarator_id, decl_inf_t.m_rv, id_line, id_pos, $class_specs);
						  		}
						  		else{
						  			if(externDef && res != null){
							  			MemberElementInfo<Method> mRes = null;

								  		try{
								  			if($data_type != null) {
								  				if($init_declarator::isDestructor == false)
							  						mRes = res.isResultMethod(decl_inf_t.m_rv, nameSp);
							  					else
							  						this.yield_error("error: return type specification for destructor invalid",
							  								 id_line, id_pos);
							  				}
							  				else {
							  					/*
							  					 * cannot fail, because isNameSpClass flag is true ...
							  					 */
							  					CpmClass _class = (CpmClass) nameSp;
							  					
							  					if($init_declarator::isDestructor == false){
							  						mRes = _class.hasDeclaredConstructor(decl_inf_t.m_pend);
							  						
							  						if($function_definition.size() > 0)
							  							$function_definition::isConstructorDefinition = true;
							  					}
							  					else{
							  						if(decl_inf_t.m_pend.getSignature().getParameters() != null){
							  							this.yield_error("error: destructors may not have parameters",
							  									 id_line, id_pos);
							  						}
							  						
							  						mRes = _class.hasDeclaredDestructor();
							  						
							  						if($function_definition.size() > 0)
							  							$function_definition::isDestructorDefinition = true;
							  					}
							  				}
							  					
							  			}
							  			catch(AmbiguousReference ambiguous){
							  				yield_error(ambiguous.getRefError(), true);
	  										System.err.print(ambiguous.getMessage());
							  			}
							  			catch(AccessSpecViolation accessViol){
							  				/*
							  				 * impossible, beacause ignore_access is set to true
							  				 */
							  			}
							  			catch(NotMatchingPrototype noMatch){
							  				yield_error(noMatch.getMessage(), id_line, id_pos);
							  				System.err.print(noMatch.makeMessage());
							  			}
							  			catch(DefinitionOfImplicitlyDeclMeth defOfImpl){
				  							this.yield_error(defOfImpl.getMessage(), id_line, id_pos);
				  						}
							  			
							  			if(mRes != null){
							  				Method m = mRes.getElement();
							  				if(!m.isDefined()){
							  					if($function_definition.size() > 0){
							  						if(isNameSpEnclosed){
							  							m.setIsDefined();
							  						}
							  						else{
							  							String methFullName = SymbolTable.getFieldsFullName(nameSp, id);
							  							this.yield_error("error: definition of '" + m.toString(methFullName) + "' is not in namespace enclosing '"
							  									 + nameSp + "'" ,
							  									 id_line,
							  									 id_pos);
							  						}
							  					}
							  					else{
							  						String err_id;
							  						if($init_declarator::isDestructor)
							  							err_id = '~' + id;
							  						else
							  							err_id = id;
							  						String methFullName = SymbolTable.getFieldsFullName(nameSp, err_id);
							  						this.yield_error("error: declaration of '" + m.toString(methFullName) + "' outside of class is not definition",
							  								  id_line, id_pos);
							  					}
							  				}
											else{
												if($function_definition.size() > 0){
													if(!isNameSpEnclosed){
														String methFullName = SymbolTable.getFieldsFullName(nameSp, id);
							  							this.yield_error("error: definition of '" + m.toString(methFullName) + "' is not in namespace enclosing '"
							  									 + nameSp + "'" ,
							  									 id_line,
							  									 id_pos);
													}
													
													String err_id = $init_declarator::isDestructor ? '~' + id : id;
													String methFullName = SymbolTable.getFieldsFullName(nameSp, err_id);
													Redefinition redef = new Redefinition(methFullName, decl_inf_t.m_rv, id_line, id_pos,
																	      m, mRes.getFileName(), mRes.getLine(), mRes.getPos());
													this.yield_error(redef.getMessage(), true);
                											this.yield_error(redef.getFinalError(), false);
												}
												else{
													String methFullName = SymbolTable.getFieldsFullName(nameSp, id);
							  						this.yield_error("error: declaration of '" + m.toString(methFullName) + "' outside of class is not definition",
							  								  id_line, id_pos);
												}
											}
							  			}
								  	}

					  				//if(this.symbolTable.isCurrentNamespaceClass() == true){
					  				if($function_definition.size() > 0){
					  					decl_inf_t.m_rv.setIsDefined();
					  					MethodDefinition methDef = (MethodDefinition) this.symbolTable.getCurrentNamespace();
					  					methDef.setMethodSign(decl_inf_t.m_rv);
					  					$function_definition::methods_type = decl_inf_t.m_rv;
					  					$function_definition::identifier = declarator_id;
					  				}
					  				
					  				/*
					  				 * TODO: check if a fuction (not a pointer to function) is 
					  				 * a parameter to another function
					  				 */
					  				if(!externDef){
					  					this.insertMethod(declarator_id, decl_inf_t.m_rv, id_line, id_pos, $class_specs, $function_definition.size() > 0 ? true : false );
					  				}
						  		}
					  		}
				  			
				  		}
				  		else if(decl_inf_t.ar_rv != null){
				  			CpmArray ar = decl_inf_t.ar_rv;
				  			$declType = ar;
				  			if($declaration.size() > 0 && $declaration::isTypedef == true){
					  			this.insertSynonym(declarator_id, ar, id_line, id_pos, $class_specs);
					  		}
					  		else{
				  				if(externDef == false){
				  					$declType = this.insertField(declarator_id, ar, id_line, id_pos, $class_specs);
				  				}
					  		}
				  		}
			  		}
			  	}
			  	
			  	if(externDef && resultNotMethod && res != null && $declType != null){
	  				MemberElementInfo<? extends Type> fld = null;
	
					try{
		  				fld = res.isResultField();
		  			}
		  			catch(AmbiguousReference ambiguous){
		  				yield_error(ambiguous.getRefError(), true);
						System.err.print(ambiguous.getMessage());
		  			}
		  			catch(AccessSpecViolation accessViol){
		  				/*
		  				 * impossible, beacause ignore_access is set to true
		  				 */
		  			}

		  			String fieldsFullName = SymbolTable.getFieldsFullName(nameSp, declarator_id);
		  			if(fld != null){
		  				//check if it is defined and that the defered is identical to the one inside the namespace ...
		  				//only for class fileds, for namespaces and others probalbly produce an error ...
		  				
		  				if(!isNameSpEnclosed){
		  					this.yield_error("error: definition of '" + fld.getElement().toString(fieldsFullName) + "' is not in namespace enclosing '"
	 									 + nameSp + "'" ,
	 									 id_line,
	 									 id_pos);
		  				}
		  				if($declType.equals(fld.getElement())){
		  					if(fld.isClassMember()){
		  						if(fld.isStatic()){
			  						if(fld.isDefined()){
			  							Redefinition redef = new Redefinition(fieldsFullName, $declType, id_line, id_pos,
			  													      fld.getElement(), fld.getStaticDefFile(),
			  													      fld.getStaticDefLine(), fld.getStaticDefPos());
			  							this.yield_error(redef.getMessage(), true);
	             										this.yield_error(redef.getFinalError(), false);
			  						}
			  						else{
			  							fld.defineStatic(id_line, id_pos, this.preproc.getCurrentFileName());
			  						}
		  						}
		  						else{
		  							this.yield_error("error: '" + fld.getElement().toString(fieldsFullName) + "' is not a static member of '" + nameSp + "'",
		  									 id_line, id_pos);
		  						}
		  					}
		  					else{
		  						Redefinition redef = new Redefinition(fieldsFullName, $declType, id_line, id_pos,
			  											      fld.getElement(), fld.getStaticDefFile(),
			  											      fld.getStaticDefLine(), fld.getStaticDefPos());
	  							this.yield_error(redef.getMessage(), true);
	     									this.yield_error(redef.getFinalError(), false);
		  					}
		  				}
		  				else{
	  						ConflictingDeclaration conflict = new ConflictingDeclaration(fieldsFullName, $declType, fld.getElement(), id_line, id_pos,
	  																	fld.getFileName(), fld.getLine(),
	  																	fld.getPos());
							this.yield_error(conflict.getMessage(), true);
							this.yield_error(conflict.getFinalError(), false);
		  				}
		  			}
		  			else{
		  				if(nameSp instanceof CpmClass){
		  					this.yield_error("error: '" + $declType.toString(fieldsFullName) + "' is not a static member of '" + nameSp + "'",
		  							 id_line, id_pos);
		  				}
		  				else{
		  					this.yield_error("error: '" + $declType.toString(fieldsFullName) + "' should have been declared inside '" + nameSp + "'",
		  							 id_line, id_pos);
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
	  
	  -> { $eq == null && $lpar == null }? ^(DECLARATION<DeclarationToken>[$declType, $init_declarator::isMethodDecl] declarator)
	  -> { $lpar == null }? ^(DECLARATION<DeclarationToken>[$declType, $init_declarator::isMethodDecl] ^('=' declarator initializer))
	  -> ^(DECLARATION<DeclarationToken>[$declType, $init_declarator::isMethodDecl] argument_expression_list)
	  //-> ^({new CommonToken(DECL, "DECL")} declarator)
	  //-> ^(DECL declarator)
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
	: glob = '::'? id scope_resolution*
	
	-> {$glob != null}? ^($glob id scope_resolution*)
	-> ^(id scope_resolution*)
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
	CpmClass _class;
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
	  	$struct_union_or_class_definition::_class = _class;
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
  	   '{' class_declaration_list stopT = '}' 
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
  	  	else if($init_declarator_list.tree == null && $declaration::isTypedef){
  	  		this.yield_warning("warning: 'typedef' was ignored in this declaration", this.fixLine($stopT), $stopT.getCharPositionInLine());
  	  	}
  	  }
  	  turn_on_normal_mode
  	  
  	  -> ^(STR_UN_CLASS_DEFINITION<StrUnClassDefToken>[$struct_union_or_class_definition::_class] class_declaration_list? /*optional in case norma_mode is false*/ init_declarator_list?)
	;
	
extern_class_definition
scope{
	UserDefinedType t;
	CpmClass _class;
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
			catch(ErrorMessage _){
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
		
		$extern_class_definition::_class = _class;
	  }
	 '{' class_declaration_list stopT = '}' 
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
  	  	else if($init_declarator_list.tree == null && $declaration::isTypedef){
  	  		this.yield_warning("warning: 'typedef' was ignored in this declaration", this.fixLine($stopT), $stopT.getCharPositionInLine());
  	  	}
  	  }
  	  turn_on_normal_mode

  	  -> ^(EXTERN_CLASS_DEFINITION<StrUnClassDefToken>[$extern_class_definition::_class] class_declaration_list? /*optional in case normal_mode is false*/ init_declarator_list?)
	;

enum_definition
scope{
	InClassDeclSpec spec;
	UserDefinedType enumeration;
	SynonymType enum_def;
}
	: 'enum' IDENTIFIER
	   {
	  	Token idTok = $IDENTIFIER;
	  	String name = idTok.getText();
	  	int line = this.fixLine(idTok);
	  	int pos = idTok.getCharPositionInLine();
	  	$enum_definition::spec = new InClassDeclSpec(false, false, false);
	  	SynonymType s_t = new SynonymType(idTok.getText(), this.symbolTable.getCurrentNamespace());
	  	$enum_definition::enumeration = new UserDefinedType(s_t, true, false);
	  	s_t.setLineAndPos(line, pos);
	  	s_t.setFileName(this.preproc.getCurrentFileName());
		$enum_definition::enum_def = s_t;
		try{
			this.symbolTable.insertInnerSyn(name, s_t);
		}
		catch(SameNameAsParentClass sameName){
			this.yield_error(sameName.getMessage(), true);
			$enum_definition::spec = null;
			$enum_definition::enumeration = null;
			s_t = null;
		}
                catch(ConflictingDeclaration conflict){
                	this.yield_error(conflict.getMessage(), true);
                	this.yield_error(conflict.getFinalError(), false);
                	$enum_definition::spec = null;
                	$enum_definition::enumeration = null;
                	s_t = null;
                }
                catch(Redefinition redef){
                	this.yield_error(redef.getMessage(), true);
                	this.yield_error(redef.getFinalError(), false);
                	$enum_definition::spec = null;
                	$enum_definition::enumeration = null;
                	s_t = null;
                }
                catch(DiffrentSymbol diffSymbol){
                	this.yield_error(diffSymbol.getMessage(), true);
                	this.yield_error(diffSymbol.getFinalError(), false);
                	$enum_definition::spec = null;
                	$enum_definition::enumeration = null;
                	s_t = null;
                }
                catch(InvalidMethodLocalDeclaration invalidMethDecl){
                	this.yield_error(invalidMethDecl.getMessage(), line, pos);
                }
	  }
	  '{' enumerator_list stopT = '}' init_declarator_list[null, $enum_definition::enumeration, new InClassDeclSpec(false, false, false)]?
	  {
  	  	if($init_declarator_list.tree != null && $init_declarator_list.newTypeInRv == true){
  	  		
  	  		Token idTok = $IDENTIFIER;
  	  		this.yield_error("note: perhaps a semicolon is missing after the definition of '" + idTok.getText() + "'",
  	  				 this.fixLine(idTok),
  	  				 idTok.getCharPositionInLine());
  	  	}
  	  	else if($init_declarator_list.tree == null && $declaration::isTypedef){
  	  		this.yield_warning("warning: 'typedef' was ignored in this declaration", this.fixLine($stopT), $stopT.getCharPositionInLine());
  	  	}
  	  }
  	  
  	  -> ^(ENUM_DEFINITION<EnumDefinitionToken>[$enum_definition::enum_def] enumerator_list init_declarator_list?)
	;

enumerator_list
	: 
	{
	   if(this.symbolTable.isCurrentNamespaceClass() == true){
  		$enum_definition::spec.isStatic = true;
  	   }
	}
	enumerator (',' enumerator)* -> enumerator+
	;

enumerator
scope{
  Type enumtor;
}
	: IDENTIFIER
	  {
	  	if($enum_definition::enumeration != null){
		  	Token idTok = $IDENTIFIER;
		  	String name = idTok.getText();
		  	int line = this.fixLine(idTok);
		  	int pos = idTok.getCharPositionInLine();
		  	$enumerator::enumtor = this.insertField(idTok.getText(), $enum_definition::enumeration, line, pos, $enum_definition::spec);
	  	}
	  }
	  (eq = '=' constant_expression)?
	  -> {$eq != null}? ^(ENUMERATOR<EnumeratorToken>[$enumerator::enumtor] ^($eq IDENTIFIER constant_expression))
	  -> ^(ENUMERATOR<EnumeratorToken>[$enumerator::enumtor] IDENTIFIER)
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
	-> ^(CLASS_DECLARATION_LIST class_content_element*)
	;
	
class_content_element
	: access_specifier ':'!
	| (declaration_specifiers? declarator '{') => function_definition 
	| in_class_declaration
	;
	
constructor
//TODO: fix error message, when ctor_initializer is not with a constructor definition
//	it's realy ugly ...
scope constructorDef;
scope normal_mode_fail_level;
@init{
  $normal_mode_fail_level::failed = false;
  $constructorDef::isDefinition = false;
}
	: construcctor_head ';' -> CONSTRUCTOR<ConstructorToken>[$construcctor_head.m]
	| 
	  {
	  	$constructorDef::isDefinition = true;
	  	DefinesNamespace in = this.symbolTable.getCurrentNamespace();
		MethodDefinition methDef = new MethodDefinition(in);
		methDef.setBelongsTo(in);

		try{
			this.symbolTable.insertMethDefinition(methDef);
		}
		catch(InvalidMethodLocalDeclaration invalidMethDecl){
			Token nextTok = input.LT(1);
			this.yield_error(invalidMethDecl.getMessage(), this.fixLine(nextTok), nextTok.getCharPositionInLine());
			this.normal_mode = false;
			$normal_mode_fail_level::failed = true;
		}
	  	this.symbolTable.setCurrentScope(methDef);
	  	this.symbolTable.setCurrentAccess(null);
	  }
	  construcctor_head (':' ctor_initializer)?
	  {$construcctor_head.m.setIsDefined();}
	  compound_statement turn_on_normal_mode
	  {
	    this.symbolTable.endScope();
	  }
	  -> ^(CONSTRUCTOR<ConstructorToken>[$construcctor_head.m] ctor_initializer? compound_statement? /*optional in case normal mode is false*/)
	;

ctor_initializer
	: mem_initializer_list
	;

mem_initializer_list
	: mem_initializer
	| mem_initializer c = ',' mem_initializer_list -> ^($c mem_initializer mem_initializer_list)
	;

mem_initializer
	: mem_initializer_id '(' expression* ')'
	;

mem_initializer_id
	: nested_identifier
	| IDENTIFIER
	;

construcctor_head returns [Method m]
@init{
	$m = null;
}
	: exp = 'explicit'? className '(' parameter_type_list? ')'
	  {
	     try{
	        ArrayList<Type> param = null;
	        boolean hasVarArgs = false;
	        Token des_id = $className.start;
	        if($parameter_type_list.tree != null){
	     	    param = $parameter_type_list.params.params;
	     	    hasVarArgs = $parameter_type_list.params.hasVarargs;
	        } 
	     
	     	DefinesNamespace parent;
	     	if($constructorDef::isDefinition){
	     		parent = ((MethodDefinition) this.symbolTable.getCurrentNamespace()).getDefinedInNamespace();
	     	}
	     	else{
	     		parent = this.symbolTable.getCurrentNamespace();
	     	}

	     	Method m1 = new Method(null, param, parent, false, false, false, false, hasVarArgs);
	     	if($exp != null) m1.setExplicit();
	     	$m = m1;
	     	this.symbolTable.insertConstructor($m, this.fixLine(des_id), des_id.getCharPositionInLine());
	     	
	     	if($constructorDef::isDefinition){
	     		((MethodDefinition) this.symbolTable.getCurrentNamespace()).setMethodSign(m1);
	     	}
	     }
	     catch(CannotBeOverloaded cBeoverld){
                this.yield_error(cBeoverld.getMessage(), true);
                this.yield_error(cBeoverld.getFinalError(), false);
             }
	  }
	;
	
destructor
scope destructorDef;
scope normal_mode_fail_level;
@init{
  $normal_mode_fail_level::failed = false;
  $destructorDef::isDefinition = false;
}
	: destructor_head ';'  -> ^(DESTRUCTOR<DestructorToken>[$destructor_head.m])
	| {
		$destructorDef::isDefinition = true;
		DefinesNamespace in = this.symbolTable.getCurrentNamespace();
		MethodDefinition methDef = new MethodDefinition(in);
		methDef.setBelongsTo(in);

		try{
			this.symbolTable.insertMethDefinition(methDef);
		}
		catch(InvalidMethodLocalDeclaration invalidMethDecl){
			Token nextTok = input.LT(1);
			this.yield_error(invalidMethDecl.getMessage(), this.fixLine(nextTok), nextTok.getCharPositionInLine());
			this.normal_mode = false;
			$normal_mode_fail_level::failed = true;
		}
	  	this.symbolTable.setCurrentScope(methDef);
	  	this.symbolTable.setCurrentAccess(null);
	  }
	  destructor_head
	  {if($destructor_head.m != null) $destructor_head.m.setIsDefined();}
	  compound_statement turn_on_normal_mode
	  {
	    this.symbolTable.endScope();
	  }
	  -> ^(DESTRUCTOR<DestructorToken>[$destructor_head.m] compound_statement? /*optional in case normal mode is false*/)
	;
	
destructor_head returns [Method m]
@init{
	$m = null;
}
	: virt = 'virtual'? '~'className '(' parameter_type_list? ')'
	{
	     try{
		     Token des_id = $className.start;
		     if($parameter_type_list.tree != null){
		     	this.yield_error("error: destructors may not have parameters", this.fixLine(des_id), des_id.getCharPositionInLine());
		     	$normal_mode_fail_level::failed = true;
		     	this.normal_mode = false;
		     }
		     else{
		     	DefinesNamespace parent;
		     	
		     	if($destructorDef::isDefinition){
		     		parent = ((MethodDefinition) this.symbolTable.getCurrentNamespace()).getDefinedInNamespace();		     		
		     	}
		     	else{
		     		parent = this.symbolTable.getCurrentNamespace();
		     	}

		     	//CpmClass _class = (CpmClass) this.symbolTable.getCurrentNamespace();
		     	Method m1 = new Method(null, null, parent, $virt == null ? false : true, false, false, false, false);
			$m = m1;
			
			if($destructorDef::isDefinition){
				((MethodDefinition) this.symbolTable.getCurrentNamespace()).setMethodSign(m1);
			}
			/*
		         * cast cannot fail because of the semantic predicate in the className rule
		         */
	     	     	((CpmClass)parent).insertDestructor($m, this.symbolTable.getCurrentAccess(), this.fixLine(des_id), des_id.getCharPositionInLine());
	
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
	| { $constructorDef.size() > 0 && $constructorDef::isDefinition }? IDENTIFIER
	| { $destructorDef.size() > 0 && $destructorDef::isDefinition }? IDENTIFIER
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

enum_specifier
options { k=3;}
	: //'enum' '{' enumerator_list '}'
	  t = 'enum' nested_name_id
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
	
	-> direct_declarator
	//| pointer
	;



direct_declarator
	:   (   nested_identifier
		{
			if($init_declarator.size() > 0){
				$init_declarator::isExternDef = true;
				$init_declarator::namespace = $nested_identifier.namespace;
				$init_declarator::isDestructor = $nested_identifier.isDestructorName;
			}
			
			if($function_definition.size() > 0){
				((MethodDefinition) this.symbolTable.getCurrentNamespace()).setBelongsTo($nested_identifier.namespace);
			}
		}
		-> nested_identifier
		| IDENTIFIER { $declarator_strings::dir_decl_identifier = $IDENTIFIER.text;
			   if($parameter_declaration.size() > 0)
			   	$parameter_declaration::p.id = $IDENTIFIER.text;
			   if($decl_id_info.size() > 0){
			   	$decl_id_info::line = this.fixLine($IDENTIFIER);
			   	$decl_id_info::pos = $IDENTIFIER.pos;
			   }
			   
			   if($function_definition.size() > 0){
			   	MethodDefinition meth = (MethodDefinition) this.symbolTable.getCurrentNamespace();
			   	meth.setBelongsTo(meth.getDefinedInNamespace());
			   }
			   if(pending_undeclared_err != null) pending_undeclared_err = null;
			   direct_declarator_error($IDENTIFIER.text, this.fixLine($IDENTIFIER), $IDENTIFIER.pos, $declarator_strings::dir_decl_error); } 
			   
			   -> IDENTIFIER
		|	'(' dcl = declarator ')' -> declarator
		)
        	declarator_suffix*
	;

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

		DefinesNamespace parent;
		
		if($init_declarator.size() > 0 && $init_declarator::isExternDef){
			parent = $init_declarator::namespace;
		}
		else{
			if($function_definition.size() > 0){
				parent = ((MethodDefinition )this.symbolTable.getCurrentNamespace()).getDefinedInNamespace();
			}
			else{
				parent = this.symbolTable.getCurrentNamespace();
			}
		}

    	  	if($parameter_type_list.tree != null){
    	  		ps = $parameter_type_list.params;
    	  		if(ps != null){
    	  			/*
    	  			 * virtual = false here because this flag is available in an other level
    	  			 */
    	  			m = new Method(null, ps.params, parent, false, 
    	  				       isAbstract, isConst, isVolatile, ps.hasVarargs);
    	  		}
    	  	}
    	  	else{
    	  		m = new Method(null, null, parent, false,
    	  			       isAbstract, isConst, isVolatile, false);
    	  	}
    	  	
    	  	if(m != null){
			DeclaratorInferedType d_inf_t = $decl_infered::declarator;
			
			if(d_inf_t == null){
				$decl_infered::declarator = new DeclaratorInferedType(m);
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
scope{
	ArrayList<ptr_cv> temp_ptrs;	//to avoid an antlr's bug 
					//(could not recognize the pointers as a parameter)
}
scope cv_qual;
@init{
	this.cv_qual_at_init();
	$pointer::temp_ptrs = $pointers;
}
	: '*' type_qualifier+ 
	      {
	      	 $pointers.add(new ptr_cv(($cv_qual::constCount != 0 ? true : false), ($cv_qual::volatileCount != 0 ? true : false)));
	      }
	      pointer[$pointer::temp_ptrs]?
	| '*'
	  {
	  	$pointers.add(new ptr_cv(false, false));
	  }
	  pointer[$pointer::temp_ptrs]
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
scope decl_id_info;
@init{
	$declarator_strings::dir_decl_identifier = null;
	$declarator_strings::dir_decl_error = null;
	$decl_infered::declarator = null;
}
	:  
	  /*todo: error if declaration is externDef*/
	  { $parameter_declaration::p = new Param(); }
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

	  		if(($function_definition.size() > 0 ||
	  		    ($constructorDef.size() > 0 && $constructorDef::isDefinition)) 
	  		    && $param != null){

	  			String id = $declarator_strings::dir_decl_identifier;
				MethodDefinition methDef = (MethodDefinition) this.symbolTable.getCurrentNamespace();
	  			if(id != null){
	  				try{
	  					methDef.insertParameter(id, $param.t, $decl_id_info::line, $decl_id_info::pos);
	  				}
	  				catch(Redefinition redef){
						this.yield_error(redef.getMessage(), true);
						this.yield_error(redef.getFinalError(), false);
					}
					catch(ChangingMeaningOf changeMean){
			                	this.yield_error(changeMean.getMessage(), true);
			                	this.yield_error(changeMean.getFinalError(), false);
			                }
	  			}
	  			else{
	  				Token start = $declaration_specifiers.start;
	  				this.yield_error("error: missing identifier for method parameter", this.fixLine(start), start.getCharPositionInLine());
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
	  -> ^(TYPE_NAME<TypeNameToken>[$id, $tp])
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
	-> initializer_list
	;

initializer_list
	: initializer (',' initializer)*
	-> ^(INITIALIZER_LIST initializer+)
	;

// E x p r e s s i o n s
 
expression
	: assignment_expression (',' assignment_expression)*
	;

assignment_expression
	: logical_or_expression assignment_operator assignment_expression -> ^(assignment_operator logical_or_expression assignment_expression)
	| conditional_expression
	;

constant_expression
	: conditional_expression
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
	: logical_or_expression (tern = '?' expression semi = ':' assignment_expression)? // the assignment_expression if from C++'s bnf ...
	
	-> {$tern != null}? ^($tern logical_or_expression ^($semi expression assignment_expression))
	-> logical_or_expression
	;

logical_or_expression
	: logical_and_expression ('||'^ logical_and_expression)*
	;

logical_and_expression
	: inclusive_or_expression ('&&'^ inclusive_or_expression)*
	;

inclusive_or_expression
	: exclusive_or_expression ('|'^ exclusive_or_expression)*
	;

//todo: assiocetivity !!! here and everywhere
exclusive_or_expression
	: and_expression ('^'^ and_expression)*
	;

and_expression
	: equality_expression ('&'^ equality_expression)*
	;

equality_expression
	: relational_expression (('=='|'!=')^ relational_expression)*
	;

relational_expression
	: shift_expression (('<'|'>'|'<='|'>=')^ shift_expression)*
	;

shift_expression
	: additive_expression (('<<'|'>>')^ additive_expression)*
	;

additive_expression
	: (multiplicative_expression) ('+'^ multiplicative_expression | '-'^ multiplicative_expression)*
	;

multiplicative_expression
	: (cast_expression) ('*'^ cast_expression | '/'^ cast_expression | '%'^ cast_expression)*
	;

cast_expression
	: '('! type_name["type name"] ')'! cast_expression
	| unary_expression
	;

unary_expression
	: postfix_expression
	| '++' cast_expression
	| '--' cast_expression
	| unary_operator cast_expression
	| 'sizeof' '('! type_name["type name"] ')'!
	| 'sizeof' unary_expression
	| new_expression
	| delete_expression
	;
	
postfix_expression
	:   (primary_expression -> primary_expression)
        (   '[' expression ']'
      	     -> ^(INDEX $postfix_expression expression)
        |   '(' argument_expression_list? ')'
            -> ^(CALL $postfix_expression argument_expression_list?)
        |   '.' IDENTIFIER
            -> ^(OBJ_ACCESS $postfix_expression nested_name_id)
        |   '->' nested_name_id
            -> ^(PTR_ACCESS $postfix_expression nested_name_id)
        |   '++'
            -> ^(INCR_POSTFIX $postfix_expression)
        |   '--'
            -> ^(DECR_POSTFIX $postfix_expression)
        )*
	;

argument_expression_list
	:   assignment_expression (',' assignment_expression)*
	;

unary_operator
	: '&'
	| '*'
	| '+'
	| '-'
	| '~'
	| '!'
	;

primary_expression
	: constant
	| 'this'
	| id_expression
	| '(' expression ')'
	;

constant
    :   HEX_LITERAL
    |   OCTAL_LITERAL
    |   DECIMAL_LITERAL
    |	CHARACTER_LITERAL
    |	STRING_LITERAL
    |   FLOATING_POINT_LITERAL
    ;

/*
 * A couple C++ features are ommited:
 * - No new_placement
 * - No global reference for new (since the global new operator is the only one that can be used)
 */
new_expression
	: n = 'new' new_type_id new_initializer? -> ^($n new_type_id ^(NEW_INITIALIZER new_initializer?))
	| n = 'new' '(' type_name["type name"] ')' new_initializer? -> ^($n type_name ^(NEW_INITIALIZER new_initializer?))
	;

new_type_id returns [Type t]
scope{
	Type inferedType;
}
@init{
	$new_type_id::inferedType = null;
}
@after{
	$t = $new_type_id::inferedType;
}
	: specifier_qualifier_list
	  {
	  	if($specifier_qualifier_list.error != null){
	  		Token st = $specifier_qualifier_list.stop;
	  		this.yield_error($specifier_qualifier_list.error + $specifier_qualifier_list.init_decl_err + " 'type name'",
	  				 this.fixLine(st), st.getCharPositionInLine());
	  	}
	  	else{
	  		$new_type_id::inferedType = $specifier_qualifier_list.t;
	  	}
	  }
	  new_declarator?
	  -> ^(NEW_TYPE_ID<NewTypeIdToken>[$new_type_id::inferedType])
	;

new_declarator
scope{
  ArrayList<ptr_cv> ptrs;
}
	: { $new_declarator::ptrs = new ArrayList<ptr_cv>(); }
	  pointer[$new_declarator::ptrs]
	  {
	  	if($new_type_id::inferedType != null){
		  	ptr_cv quals = $new_declarator::ptrs.get(0);
	    		Pointer ptr = new Pointer(null, quals.isConst, quals.isVolatile);
	    		Pointer pending = ptr;
	    		for(int i = 1 ; i < $new_declarator::ptrs.size() ; ++i){
	    			quals = $new_declarator::ptrs.get(i);
	    			Pointer temp = new Pointer(null, quals.isConst, quals.isVolatile);
	    			pending.setPointsTo(temp);
	    			pending = temp;
	    		}
	    		pending.setPointsTo($new_type_id::inferedType);
	    		$new_type_id::inferedType = pending;
    		}
	  }
	  new_declarator?
	| direct_new_declarator
	;

direct_new_declarator
	: '[' expression ']' 
	   direct_new_declarator_tail[0]?
	   {
	   	if($new_type_id::inferedType != null) 
	  		$new_type_id::inferedType = new Pointer($new_type_id::inferedType, false, false);
	   }
	;

direct_new_declarator_tail[int depth]
scope{
	int tmpDepth;
}
@init{
	$direct_new_declarator_tail::tmpDepth = depth;
}
	: '[' constant_expression ']' 
	   {
	   	if($new_type_id::inferedType != null)
	   		if(depth == 0){
	   			$new_type_id::inferedType = new CpmArray($new_type_id::inferedType, 1);
	   		}
	   		else{
	   			((CpmArray)$new_type_id::inferedType).increaseDimensions();
	   		}
	   }
	   direct_new_declarator_tail[$direct_new_declarator_tail::tmpDepth++]
	| '[' constant_expression ']'
	   {
	   	if($new_type_id::inferedType != null)
	   		if(depth == 0){
	   			$new_type_id::inferedType = new CpmArray($new_type_id::inferedType, 1);
	   		}
	   		else{
	   			((CpmArray)$new_type_id::inferedType).increaseDimensions();
	   		}
	   }
	;

new_initializer
	: '(' argument_expression_list? ')'
	;

delete_expression
	: 'delete' cast_expression
	| 'delete' '[' ']' cast_expression
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
	: /*IDENTIFIER ':' statement
	|*/
	  c = 'case' constant_expression sem = ':' statement -> ^(CASE_STMT[$c] constant_expression ^(CASE_SLCT[$sem] statement))
	| def = 'default' sem = ':' statement -> ^(DEFAULT_STMT[$def] ^(CASE_SLCT[$sem] statement))
	;

compound_statement
scope{
	MethodDefinition methDef;
}
	: 
	  {
	  	$compound_statement::methDef = (MethodDefinition) this.symbolTable.getCurrentNamespace();
	  	$compound_statement::methDef.enterNewBlock();
	  }
	  '{' ( declaration
	      | statement)* '}'	//declarations not only at the begining of a compound statement
	  {
	   	$compound_statement::methDef.exitBlock();
	  }
	;
	


expression_statement
	: ';'
	| expression ';'!
	;
/*
 * There is no variable declaration iside a condition (like C++)
 * Only inside the for_init_statement .
 */
selection_statement
	: i = 'if' '(' expression ')' stmt1 = statement (options {k=1; backtrack=false;}: else_prt = 'else' stmt2 = statement)?
	  -> {$else_prt == null}? ^(IF_STMT[$i] expression $stmt1)
	  -> ^(IF_ELSE_STMT[$i] expression $stmt1 ^(ELSE_PRT[$else_prt] $stmt2))
	| s = 'switch' '(' expression ')' statement
	  -> ^(SWITCH_STMT[$s] expression statement)
	;

iteration_statement
	: w = 'while' '(' expression ')' statement
	-> ^(WHILE_COND[$w] expression ^(WHILE_BODY statement))
	| d = 'do' statement 'while' '(' expression ')' ';'
	 -> ^(DO_WHILE_STMT[$d] ^(DO_WHILE_BODY statement) ^(WHILE_COND[$w] expression))
	| f = 'for' '(' for_init_statement expression_statement expression? ')' statement
	-> ^(FOR_STMT[$f] for_init_statement expression_statement expression? ^(FOR_BODY statement))
	;
			
for_init_statement
	: simple_declaration ';'!
	| expression_statement
	;


jump_statement	: /*'goto' IDENTIFIER ';'
	|*/ 
	  'continue' ';'!
	| 'break' ';'!
	| ret = 'return' exp = expression? ';'
	  -> {$exp.tree != null}? ^(RETURN_EXP[$ret] expression)
	  -> ^(RETURN_EXP[$ret])
	;
	
//C+- aux rules (different rules to adjust C's syntax)


id_expression
	: global_scope = '::'? IDENTIFIER id_expression_tail?
	-> { $global_scope != null }? ^(ID_EXPRESSION<IdExpressionToken> '::' id_expression_tail?)
	-> ^(ID_EXPRESSION<IdExpressionToken> id_expression_tail?)
	;

id_expression_tail
	: '::' IDENTIFIER id_expression_tail
	-> ^('::' IDENTIFIER id_expression_tail)
	| IDENTIFIER
	-> ^(IDENTIFIER)
	;


nested_identifier returns [DefinesNamespace namespace, boolean isDestructorName]
scope{
  DefinesNamespace fromScope;
  DefinesNamespace runner;
  boolean destructorName;
}
@init{
	$nested_identifier::destructorName = false;
	$namespace = null;
}
	: global_scope = '::'? IDENTIFIER
	  {
	  	DefinesNamespace currentScope = this.symbolTable.getCurrentNamespace();

	  	if(   $function_definition.size() > 0
	  	   || ($constructorDef.size() > 0 && $constructorDef::isDefinition)
	  	   || ($destructorDef.size() > 0 && $destructorDef::isDefinition)){
	  		currentScope = ((MethodDefinition) currentScope).getDefinedInNamespace();
	  	}
	  	
	  	$nested_identifier::fromScope = currentScope;
	  	DefinesNamespace runner = null;
	  	String id = $IDENTIFIER.text;
	  	try{
		  	if($global_scope == null){
		  		runner = currentScope.findNamespace(id, currentScope, true);
		  	}
		  	else{
		  		runner = this.symbolTable.findInnerNamespace(id, currentScope, true);
		  	}
	  	}
	  	catch(AmbiguousReference ambiguous){
	  		ambiguous.referenceTypeError(this.fixLine($IDENTIFIER), $IDENTIFIER.pos);
		  	yield_error(ambiguous.getRefError(), true);
			System.err.print(ambiguous.getMessage());
			//yield_error(ambiguous.getLastLine(), true);
	  	}
	  	catch(AccessSpecViolation access_viol){
	  		yield_error(access_viol.getMessage(), false);
		  	yield_error(access_viol.getContextError(), true);
	  	}
	  	catch(InvalidScopeResolution invalid){
	  		yield_error(invalid.getMessage(), true);
	  	}
	  	
	  	$nested_identifier::runner = runner;
	  }
	  '::' nested_identifier_tail
	  {
	  	$namespace = $nested_identifier::runner;
	  	$isDestructorName = $nested_identifier::destructorName;
	  }
	  -> { $global_scope != null}? ^(NESTED_IDENTIFIER<NestedIdentifierToken>[$namespace, $declarator_strings::dir_decl_identifier] '::' IDENTIFIER ^('::' nested_identifier_tail))
	  -> ^(NESTED_IDENTIFIER<NestedIdentifierToken>[$namespace, $declarator_strings::dir_decl_identifier] IDENTIFIER '::' nested_identifier_tail)
	;
	
nested_identifier_tail
	: IDENTIFIER
	  {
	  	if($nested_identifier::runner != null){
	  		DefinesNamespace next = null;
		  	try{
		  		String id = $IDENTIFIER.text;
		  		next = $nested_identifier::runner.findInnerNamespace(id, $nested_identifier::fromScope, true);
		  	}
		  	catch(AmbiguousReference ambiguous){
		  		ambiguous.referenceTypeError(this.fixLine($IDENTIFIER), $IDENTIFIER.pos);
			  	yield_error(ambiguous.getRefError(), true);
				System.err.print(ambiguous.getMessage());
		  	}
		  	catch(AccessSpecViolation access_viol){
		  		yield_error(access_viol.getMessage(), false);
			  	yield_error(access_viol.getContextError(), true);
		  	}
		  	catch(InvalidScopeResolution invalid){
		  		yield_error(invalid.getMessage(), true);
		  	}
		  	$nested_identifier::runner = next;
	  	}
	  }
	  '::' nested_identifier_tail
	  -> ^(IDENTIFIER '::' nested_identifier_tail)
	| destrName = '~'? IDENTIFIER
	  {
	  	$declarator_strings::dir_decl_identifier = $IDENTIFIER.text;
		if($parameter_declaration.size() > 0) $parameter_declaration::p.id = $IDENTIFIER.text;
		if($decl_id_info.size() > 0){
			$decl_id_info::line = this.fixLine($IDENTIFIER);
			$decl_id_info::pos = $IDENTIFIER.pos;
		}
		
		if($destrName != null) $nested_identifier::destructorName = true;

		direct_declarator_error($IDENTIFIER.text, this.fixLine($IDENTIFIER), $IDENTIFIER.pos, $declarator_strings::dir_decl_error);
	  }
	  -> {$destrName == null}? ^(IDENTIFIER)
	  -> ^($destrName IDENTIFIER)
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
	int baseLine;
	int preprocLine;
	int includeLine;
	String fileName;
}
@init{
	$line_marker::is_enter = false;
	$line_marker::is_exit = false;
	$line_marker::is_stl_header = false;
}
	: h_tag = '#' DECIMAL_LITERAL STRING_LITERAL line_marker_flags? { String file = $STRING_LITERAL.text;
									  $line_marker::fileName = file.substring(1, file.length() - 1);
									  $line_marker::baseLine = Integer.parseInt($DECIMAL_LITERAL.text);
									  $line_marker::preprocLine = $h_tag.line;

									  //ignore preproc useless stuff 
									  if(file.equals("\"<built-in>\"") == false && file.equals("\"<command-line>\"") == false){
									  
									  	  this.inStlFile = $line_marker::is_stl_header;
									  	  this.stlFile = file;

										  if($line_marker::is_enter == true){
										  	$line_marker::includeLine = this.fixLine($h_tag);
										  	this.preproc.enterIncludedFile($line_marker::fileName, 
										  				       $line_marker::baseLine,
										  				       $line_marker::preprocLine,
										  				       $line_marker::includeLine);
										  }
										  else if($line_marker::is_exit == true){
										  	this.preproc.exitIncludedFile($line_marker::baseLine, $line_marker::preprocLine);
										  	$line_marker::is_stl_header = false;
										  }
										  else{
										  	$line_marker::includeLine = $line_marker::preprocLine;
										  	this.preproc.enterIncludedFile($line_marker::fileName,
										  				       $line_marker::baseLine,
										  				       $line_marker::preprocLine,
										  				       $line_marker::includeLine);
										  }
									  }
									}
									-> { $line_marker::is_exit }? ^(LINE_MARKER_EXIT<LineMarkerToken>[$line_marker::baseLine,
																          $line_marker::preprocLine,
																          $line_marker::is_stl_header])
									-> ^(LINE_MARKER_ENTER<EntryLineMarkerToken>[$line_marker::baseLine,
														     $line_marker::preprocLine,
														     $line_marker::is_stl_header,
														     $line_marker::fileName,
														     $line_marker::includeLine])
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
	  
	  -> ^(DECIMAL_LITERAL line_marker_flags)
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
