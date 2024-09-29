(function dartProgram(){function copyProperties(a,b){var s=Object.keys(a)
for(var r=0;r<s.length;r++){var q=s[r]
b[q]=a[q]}}function mixinPropertiesHard(a,b){var s=Object.keys(a)
for(var r=0;r<s.length;r++){var q=s[r]
if(!b.hasOwnProperty(q)){b[q]=a[q]}}}function mixinPropertiesEasy(a,b){Object.assign(b,a)}var z=function(){var s=function(){}
s.prototype={p:{}}
var r=new s()
if(!(Object.getPrototypeOf(r)&&Object.getPrototypeOf(r).p===s.prototype.p))return false
try{if(typeof navigator!="undefined"&&typeof navigator.userAgent=="string"&&navigator.userAgent.indexOf("Chrome/")>=0)return true
if(typeof version=="function"&&version.length==0){var q=version()
if(/^\d+\.\d+\.\d+\.\d+$/.test(q))return true}}catch(p){}return false}()
function inherit(a,b){a.prototype.constructor=a
a.prototype["$i"+a.name]=a
if(b!=null){if(z){Object.setPrototypeOf(a.prototype,b.prototype)
return}var s=Object.create(b.prototype)
copyProperties(a.prototype,s)
a.prototype=s}}function inheritMany(a,b){for(var s=0;s<b.length;s++){inherit(b[s],a)}}function mixinEasy(a,b){mixinPropertiesEasy(b.prototype,a.prototype)
a.prototype.constructor=a}function mixinHard(a,b){mixinPropertiesHard(b.prototype,a.prototype)
a.prototype.constructor=a}function lazy(a,b,c,d){var s=a
a[b]=s
a[c]=function(){if(a[b]===s){a[b]=d()}a[c]=function(){return this[b]}
return a[b]}}function lazyFinal(a,b,c,d){var s=a
a[b]=s
a[c]=function(){if(a[b]===s){var r=d()
if(a[b]!==s){A.h3(b)}a[b]=r}var q=a[b]
a[c]=function(){return q}
return q}}function makeConstList(a){a.immutable$list=Array
a.fixed$length=Array
return a}function convertToFastObject(a){function t(){}t.prototype=a
new t()
return a}function convertAllToFastObject(a){for(var s=0;s<a.length;++s){convertToFastObject(a[s])}}var y=0
function instanceTearOffGetter(a,b){var s=null
return a?function(c){if(s===null)s=A.cX(b)
return new s(c,this)}:function(){if(s===null)s=A.cX(b)
return new s(this,null)}}function staticTearOffGetter(a){var s=null
return function(){if(s===null)s=A.cX(a).prototype
return s}}var x=0
function tearOffParameters(a,b,c,d,e,f,g,h,i,j){if(typeof h=="number"){h+=x}return{co:a,iS:b,iI:c,rC:d,dV:e,cs:f,fs:g,fT:h,aI:i||0,nDA:j}}function installStaticTearOff(a,b,c,d,e,f,g,h){var s=tearOffParameters(a,true,false,c,d,e,f,g,h,false)
var r=staticTearOffGetter(s)
a[b]=r}function installInstanceTearOff(a,b,c,d,e,f,g,h,i,j){c=!!c
var s=tearOffParameters(a,false,c,d,e,f,g,h,i,!!j)
var r=instanceTearOffGetter(c,s)
a[b]=r}function setOrUpdateInterceptorsByTag(a){var s=v.interceptorsByTag
if(!s){v.interceptorsByTag=a
return}copyProperties(a,s)}function setOrUpdateLeafTags(a){var s=v.leafTags
if(!s){v.leafTags=a
return}copyProperties(a,s)}function updateTypes(a){var s=v.types
var r=s.length
s.push.apply(s,a)
return r}function updateHolder(a,b){copyProperties(b,a)
return a}var hunkHelpers=function(){var s=function(a,b,c,d,e){return function(f,g,h,i){return installInstanceTearOff(f,g,a,b,c,d,[h],i,e,false)}},r=function(a,b,c,d){return function(e,f,g,h){return installStaticTearOff(e,f,a,b,c,[g],h,d)}}
return{inherit:inherit,inheritMany:inheritMany,mixin:mixinEasy,mixinHard:mixinHard,installStaticTearOff:installStaticTearOff,installInstanceTearOff:installInstanceTearOff,_instance_0u:s(0,0,null,["$0"],0),_instance_1u:s(0,1,null,["$1"],0),_instance_2u:s(0,2,null,["$2"],0),_instance_0i:s(1,0,null,["$0"],0),_instance_1i:s(1,1,null,["$1"],0),_instance_2i:s(1,2,null,["$2"],0),_static_0:r(0,null,["$0"],0),_static_1:r(1,null,["$1"],0),_static_2:r(2,null,["$2"],0),makeConstList:makeConstList,lazy:lazy,lazyFinal:lazyFinal,updateHolder:updateHolder,convertToFastObject:convertToFastObject,updateTypes:updateTypes,setOrUpdateInterceptorsByTag:setOrUpdateInterceptorsByTag,setOrUpdateLeafTags:setOrUpdateLeafTags}}()
function initializeDeferredHunk(a){x=v.types.length
a(hunkHelpers,v,w,$)}var J={
d2(a,b,c,d){return{i:a,p:b,e:c,x:d}},
cZ(a){var s,r,q,p,o,n=a[v.dispatchPropertyName]
if(n==null)if($.d_==null){A.fS()
n=a[v.dispatchPropertyName]}if(n!=null){s=n.p
if(!1===s)return n.i
if(!0===s)return a
r=Object.getPrototypeOf(a)
if(s===r)return n.i
if(n.e===r)throw A.b(A.dn("Return interceptor for "+A.o(s(a,n))))}q=a.constructor
if(q==null)p=null
else{o=$.cj
if(o==null)o=$.cj=v.getIsolateTag("_$dart_js")
p=q[o]}if(p!=null)return p
p=A.fY(a)
if(p!=null)return p
if(typeof a=="function")return B.r
s=Object.getPrototypeOf(a)
if(s==null)return B.e
if(s===Object.prototype)return B.e
if(typeof q=="function"){o=$.cj
if(o==null)o=$.cj=v.getIsolateTag("_$dart_js")
Object.defineProperty(q,o,{value:B.b,enumerable:false,writable:true,configurable:true})
return B.b}return B.b},
df(a){a.fixed$length=Array
return a},
ad(a){if(typeof a=="number"){if(Math.floor(a)==a)return J.ai.prototype
return J.b3.prototype}if(typeof a=="string")return J.Y.prototype
if(a==null)return J.aj.prototype
if(typeof a=="boolean")return J.b2.prototype
if(Array.isArray(a))return J.t.prototype
if(typeof a!="object"){if(typeof a=="function")return J.J.prototype
if(typeof a=="symbol")return J.am.prototype
if(typeof a=="bigint")return J.ak.prototype
return a}if(a instanceof A.d)return a
return J.cZ(a)},
dW(a){if(typeof a=="string")return J.Y.prototype
if(a==null)return a
if(Array.isArray(a))return J.t.prototype
if(typeof a!="object"){if(typeof a=="function")return J.J.prototype
if(typeof a=="symbol")return J.am.prototype
if(typeof a=="bigint")return J.ak.prototype
return a}if(a instanceof A.d)return a
return J.cZ(a)},
cY(a){if(a==null)return a
if(Array.isArray(a))return J.t.prototype
if(typeof a!="object"){if(typeof a=="function")return J.J.prototype
if(typeof a=="symbol")return J.am.prototype
if(typeof a=="bigint")return J.ak.prototype
return a}if(a instanceof A.d)return a
return J.cZ(a)},
ed(a,b){return J.cY(a).E(a,b)},
d7(a){return J.ad(a).gn(a)},
ee(a){return J.cY(a).gq(a)},
cM(a){return J.dW(a).gj(a)},
ef(a){return J.ad(a).gk(a)},
eg(a,b,c){return J.cY(a).F(a,b,c)},
aT(a){return J.ad(a).h(a)},
b1:function b1(){},
b2:function b2(){},
aj:function aj(){},
al:function al(){},
K:function K(){},
bh:function bh(){},
aw:function aw(){},
J:function J(){},
ak:function ak(){},
am:function am(){},
t:function t(a){this.$ti=a},
bN:function bN(a){this.$ti=a},
aV:function aV(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
b4:function b4(){},
ai:function ai(){},
b3:function b3(){},
Y:function Y(){}},A={cP:function cP(){},
cC(a,b,c){return a},
d0(a){var s,r
for(s=$.v.length,r=0;r<s;++r)if(a===$.v[r])return!0
return!1},
ex(a,b,c,d){if(t.V.b(a))return new A.af(a,b,c.i("@<0>").u(d).i("af<1,2>"))
return new A.R(a,b,c.i("@<0>").u(d).i("R<1,2>"))},
an:function an(a){this.a=a},
e:function e(){},
L:function L(){},
Z:function Z(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
R:function R(a,b,c){this.a=a
this.b=b
this.$ti=c},
af:function af(a,b,c){this.a=a
this.b=b
this.$ti=c},
b6:function b6(a,b,c){var _=this
_.a=null
_.b=a
_.c=b
_.$ti=c},
B:function B(a,b,c){this.a=a
this.b=b
this.$ti=c},
ah:function ah(){},
e2(a){var s=v.mangledGlobalNames[a]
if(s!=null)return s
return"minified:"+a},
hB(a,b){var s
if(b!=null){s=b.x
if(s!=null)return s}return t.p.b(a)},
o(a){var s
if(typeof a=="string")return a
if(typeof a=="number"){if(a!==0)return""+a}else if(!0===a)return"true"
else if(!1===a)return"false"
else if(a==null)return"null"
s=J.aT(a)
return s},
at(a){var s,r=$.dg
if(r==null)r=$.dg=Symbol("identityHashCode")
s=a[r]
if(s==null){s=Math.random()*0x3fffffff|0
a[r]=s}return s},
bQ(a){return A.ey(a)},
ey(a){var s,r,q,p
if(a instanceof A.d)return A.r(A.ae(a),null)
s=J.ad(a)
if(s===B.n||s===B.t||t.o.b(a)){r=B.c(a)
if(r!=="Object"&&r!=="")return r
q=a.constructor
if(typeof q=="function"){p=q.name
if(typeof p=="string"&&p!=="Object"&&p!=="")return p}}return A.r(A.ae(a),null)},
eA(a){if(typeof a=="number"||A.cy(a))return J.aT(a)
if(typeof a=="string")return JSON.stringify(a)
if(a instanceof A.Q)return a.h(0)
return"Instance of '"+A.bQ(a)+"'"},
ez(a){var s=a.$thrownJsError
if(s==null)return null
return A.H(s)},
z(a,b){if(a==null)J.cM(a)
throw A.b(A.dU(a,b))},
dU(a,b){var s,r="index"
if(!A.dK(b))return new A.y(!0,b,r,null)
s=J.cM(a)
if(b<0||b>=s)return A.er(b,s,a,r)
return new A.au(null,null,!0,b,r,"Value not in range")},
b(a){return A.dY(new Error(),a)},
dY(a,b){var s
if(b==null)b=new A.D()
a.dartException=b
s=A.h4
if("defineProperty" in Object){Object.defineProperty(a,"message",{get:s})
a.name=""}else a.toString=s
return a},
h4(){return J.aT(this.dartException)},
aS(a){throw A.b(a)},
e0(a,b){throw A.dY(b,a)},
h2(a){throw A.b(A.bG(a))},
E(a){var s,r,q,p,o,n
a=A.h1(a.replace(String({}),"$receiver$"))
s=a.match(/\\\$[a-zA-Z]+\\\$/g)
if(s==null)s=A.bC([],t.s)
r=s.indexOf("\\$arguments\\$")
q=s.indexOf("\\$argumentsExpr\\$")
p=s.indexOf("\\$expr\\$")
o=s.indexOf("\\$method\\$")
n=s.indexOf("\\$receiver\\$")
return new A.bV(a.replace(new RegExp("\\\\\\$arguments\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$argumentsExpr\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$expr\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$method\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$receiver\\\\\\$","g"),"((?:x|[^x])*)"),r,q,p,o,n)},
bW(a){return function($expr$){var $argumentsExpr$="$arguments$"
try{$expr$.$method$($argumentsExpr$)}catch(s){return s.message}}(a)},
dm(a){return function($expr$){try{$expr$.$method$}catch(s){return s.message}}(a)},
cQ(a,b){var s=b==null,r=s?null:b.method
return new A.b5(a,r,s?null:b.receiver)},
P(a){if(a==null)return new A.bP(a)
if(a instanceof A.ag)return A.O(a,a.a)
if(typeof a!=="object")return a
if("dartException" in a)return A.O(a,a.dartException)
return A.fE(a)},
O(a,b){if(t.Q.b(b))if(b.$thrownJsError==null)b.$thrownJsError=a
return b},
fE(a){var s,r,q,p,o,n,m,l,k,j,i,h,g
if(!("message" in a))return a
s=a.message
if("number" in a&&typeof a.number=="number"){r=a.number
q=r&65535
if((B.p.aF(r,16)&8191)===10)switch(q){case 438:return A.O(a,A.cQ(A.o(s)+" (Error "+q+")",null))
case 445:case 5007:A.o(s)
return A.O(a,new A.as())}}if(a instanceof TypeError){p=$.e3()
o=$.e4()
n=$.e5()
m=$.e6()
l=$.e9()
k=$.ea()
j=$.e8()
$.e7()
i=$.ec()
h=$.eb()
g=p.t(s)
if(g!=null)return A.O(a,A.cQ(s,g))
else{g=o.t(s)
if(g!=null){g.method="call"
return A.O(a,A.cQ(s,g))}else if(n.t(s)!=null||m.t(s)!=null||l.t(s)!=null||k.t(s)!=null||j.t(s)!=null||m.t(s)!=null||i.t(s)!=null||h.t(s)!=null)return A.O(a,new A.as())}return A.O(a,new A.bl(typeof s=="string"?s:""))}if(a instanceof RangeError){if(typeof s=="string"&&s.indexOf("call stack")!==-1)return new A.av()
s=function(b){try{return String(b)}catch(f){}return null}(a)
return A.O(a,new A.y(!1,null,null,typeof s=="string"?s.replace(/^RangeError:\s*/,""):s))}if(typeof InternalError=="function"&&a instanceof InternalError)if(typeof s=="string"&&s==="too much recursion")return new A.av()
return a},
H(a){var s
if(a instanceof A.ag)return a.b
if(a==null)return new A.aI(a)
s=a.$cachedTrace
if(s!=null)return s
s=new A.aI(a)
if(typeof a==="object")a.$cachedTrace=s
return s},
d3(a){if(a==null)return J.d7(a)
if(typeof a=="object")return A.at(a)
return J.d7(a)},
fh(a,b,c,d,e,f){switch(b){case 0:return a.$0()
case 1:return a.$1(c)
case 2:return a.$2(c,d)
case 3:return a.$3(c,d,e)
case 4:return a.$4(c,d,e,f)}throw A.b(new A.c6("Unsupported number of arguments for wrapped closure"))},
cD(a,b){var s=a.$identity
if(!!s)return s
s=A.fM(a,b)
a.$identity=s
return s},
fM(a,b){var s
switch(b){case 0:s=a.$0
break
case 1:s=a.$1
break
case 2:s=a.$2
break
case 3:s=a.$3
break
case 4:s=a.$4
break
default:s=null}if(s!=null)return s.bind(a)
return function(c,d,e){return function(f,g,h,i){return e(c,d,f,g,h,i)}}(a,b,A.fh)},
eo(a2){var s,r,q,p,o,n,m,l,k,j,i=a2.co,h=a2.iS,g=a2.iI,f=a2.nDA,e=a2.aI,d=a2.fs,c=a2.cs,b=d[0],a=c[0],a0=i[b],a1=a2.fT
a1.toString
s=h?Object.create(new A.bR().constructor.prototype):Object.create(new A.aZ(null,null).constructor.prototype)
s.$initialize=s.constructor
r=h?function static_tear_off(){this.$initialize()}:function tear_off(a3,a4){this.$initialize(a3,a4)}
s.constructor=r
r.prototype=s
s.$_name=b
s.$_target=a0
q=!h
if(q)p=A.dd(b,a0,g,f)
else{s.$static_name=b
p=a0}s.$S=A.ek(a1,h,g)
s[a]=p
for(o=p,n=1;n<d.length;++n){m=d[n]
if(typeof m=="string"){l=i[m]
k=m
m=l}else k=""
j=c[n]
if(j!=null){if(q)m=A.dd(k,m,g,f)
s[j]=m}if(n===e)o=m}s.$C=o
s.$R=a2.rC
s.$D=a2.dV
return r},
ek(a,b,c){if(typeof a=="number")return a
if(typeof a=="string"){if(b)throw A.b("Cannot compute signature for static tearoff.")
return function(d,e){return function(){return e(this,d)}}(a,A.ei)}throw A.b("Error in functionType of tearoff")},
el(a,b,c,d){var s=A.dc
switch(b?-1:a){case 0:return function(e,f){return function(){return f(this)[e]()}}(c,s)
case 1:return function(e,f){return function(g){return f(this)[e](g)}}(c,s)
case 2:return function(e,f){return function(g,h){return f(this)[e](g,h)}}(c,s)
case 3:return function(e,f){return function(g,h,i){return f(this)[e](g,h,i)}}(c,s)
case 4:return function(e,f){return function(g,h,i,j){return f(this)[e](g,h,i,j)}}(c,s)
case 5:return function(e,f){return function(g,h,i,j,k){return f(this)[e](g,h,i,j,k)}}(c,s)
default:return function(e,f){return function(){return e.apply(f(this),arguments)}}(d,s)}},
dd(a,b,c,d){if(c)return A.en(a,b,d)
return A.el(b.length,d,a,b)},
em(a,b,c,d){var s=A.dc,r=A.ej
switch(b?-1:a){case 0:throw A.b(new A.bi("Intercepted function with no arguments."))
case 1:return function(e,f,g){return function(){return f(this)[e](g(this))}}(c,r,s)
case 2:return function(e,f,g){return function(h){return f(this)[e](g(this),h)}}(c,r,s)
case 3:return function(e,f,g){return function(h,i){return f(this)[e](g(this),h,i)}}(c,r,s)
case 4:return function(e,f,g){return function(h,i,j){return f(this)[e](g(this),h,i,j)}}(c,r,s)
case 5:return function(e,f,g){return function(h,i,j,k){return f(this)[e](g(this),h,i,j,k)}}(c,r,s)
case 6:return function(e,f,g){return function(h,i,j,k,l){return f(this)[e](g(this),h,i,j,k,l)}}(c,r,s)
default:return function(e,f,g){return function(){var q=[g(this)]
Array.prototype.push.apply(q,arguments)
return e.apply(f(this),q)}}(d,r,s)}},
en(a,b,c){var s,r
if($.da==null)$.da=A.d9("interceptor")
if($.db==null)$.db=A.d9("receiver")
s=b.length
r=A.em(s,c,a,b)
return r},
cX(a){return A.eo(a)},
ei(a,b){return A.cs(v.typeUniverse,A.ae(a.a),b)},
dc(a){return a.a},
ej(a){return a.b},
d9(a){var s,r,q,p=new A.aZ("receiver","interceptor"),o=J.df(Object.getOwnPropertyNames(p))
for(s=o.length,r=0;r<s;++r){q=o[r]
if(p[q]===a)return q}throw A.b(A.aU("Field name "+a+" not found.",null))},
hC(a){throw A.b(new A.bq(a))},
fO(a){return v.getIsolateTag(a)},
fY(a){var s,r,q,p,o,n=$.dX.$1(a),m=$.cE[n]
if(m!=null){Object.defineProperty(a,v.dispatchPropertyName,{value:m,enumerable:false,writable:true,configurable:true})
return m.i}s=$.cI[n]
if(s!=null)return s
r=v.interceptorsByTag[n]
if(r==null){q=$.dR.$2(a,n)
if(q!=null){m=$.cE[q]
if(m!=null){Object.defineProperty(a,v.dispatchPropertyName,{value:m,enumerable:false,writable:true,configurable:true})
return m.i}s=$.cI[q]
if(s!=null)return s
r=v.interceptorsByTag[q]
n=q}}if(r==null)return null
s=r.prototype
p=n[0]
if(p==="!"){m=A.cL(s)
$.cE[n]=m
Object.defineProperty(a,v.dispatchPropertyName,{value:m,enumerable:false,writable:true,configurable:true})
return m.i}if(p==="~"){$.cI[n]=s
return s}if(p==="-"){o=A.cL(s)
Object.defineProperty(Object.getPrototypeOf(a),v.dispatchPropertyName,{value:o,enumerable:false,writable:true,configurable:true})
return o.i}if(p==="+")return A.dZ(a,s)
if(p==="*")throw A.b(A.dn(n))
if(v.leafTags[n]===true){o=A.cL(s)
Object.defineProperty(Object.getPrototypeOf(a),v.dispatchPropertyName,{value:o,enumerable:false,writable:true,configurable:true})
return o.i}else return A.dZ(a,s)},
dZ(a,b){var s=Object.getPrototypeOf(a)
Object.defineProperty(s,v.dispatchPropertyName,{value:J.d2(b,s,null,null),enumerable:false,writable:true,configurable:true})
return b},
cL(a){return J.d2(a,!1,null,!!a.$iu)},
fZ(a,b,c){var s=b.prototype
if(v.leafTags[a]===true)return A.cL(s)
else return J.d2(s,c,null,null)},
fS(){if(!0===$.d_)return
$.d_=!0
A.fT()},
fT(){var s,r,q,p,o,n,m,l
$.cE=Object.create(null)
$.cI=Object.create(null)
A.fR()
s=v.interceptorsByTag
r=Object.getOwnPropertyNames(s)
if(typeof window!="undefined"){window
q=function(){}
for(p=0;p<r.length;++p){o=r[p]
n=$.e_.$1(o)
if(n!=null){m=A.fZ(o,s[o],n)
if(m!=null){Object.defineProperty(n,v.dispatchPropertyName,{value:m,enumerable:false,writable:true,configurable:true})
q.prototype=n}}}}for(p=0;p<r.length;++p){o=r[p]
if(/^[A-Za-z_]/.test(o)){l=s[o]
s["!"+o]=l
s["~"+o]=l
s["-"+o]=l
s["+"+o]=l
s["*"+o]=l}}},
fR(){var s,r,q,p,o,n,m=B.f()
m=A.ac(B.h,A.ac(B.i,A.ac(B.d,A.ac(B.d,A.ac(B.j,A.ac(B.k,A.ac(B.l(B.c),m)))))))
if(typeof dartNativeDispatchHooksTransformer!="undefined"){s=dartNativeDispatchHooksTransformer
if(typeof s=="function")s=[s]
if(Array.isArray(s))for(r=0;r<s.length;++r){q=s[r]
if(typeof q=="function")m=q(m)||m}}p=m.getTag
o=m.getUnknownTag
n=m.prototypeForTag
$.dX=new A.cF(p)
$.dR=new A.cG(o)
$.e_=new A.cH(n)},
ac(a,b){return a(b)||b},
fN(a,b){var s=b.length,r=v.rttc[""+s+";"+a]
if(r==null)return null
if(s===0)return r
if(s===r.length)return r.apply(null,b)
return r(b)},
h1(a){if(/[[\]{}()*+?.\\^$|]/.test(a))return a.replace(/[[\]{}()*+?.\\^$|]/g,"\\$&")
return a},
bV:function bV(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
as:function as(){},
b5:function b5(a,b,c){this.a=a
this.b=b
this.c=c},
bl:function bl(a){this.a=a},
bP:function bP(a){this.a=a},
ag:function ag(a,b){this.a=a
this.b=b},
aI:function aI(a){this.a=a
this.b=null},
Q:function Q(){},
bE:function bE(){},
bF:function bF(){},
bU:function bU(){},
bR:function bR(){},
aZ:function aZ(a,b){this.a=a
this.b=b},
bq:function bq(a){this.a=a},
bi:function bi(a){this.a=a},
cF:function cF(a){this.a=a},
cG:function cG(a){this.a=a},
cH:function cH(a){this.a=a},
V(a,b,c){if(a>>>0!==a||a>=c)throw A.b(A.dU(b,a))},
b7:function b7(){},
aq:function aq(){},
b8:function b8(){},
a0:function a0(){},
ao:function ao(){},
ap:function ap(){},
b9:function b9(){},
ba:function ba(){},
bb:function bb(){},
bc:function bc(){},
bd:function bd(){},
be:function be(){},
bf:function bf(){},
ar:function ar(){},
bg:function bg(){},
aD:function aD(){},
aE:function aE(){},
aF:function aF(){},
aG:function aG(){},
dh(a,b){var s=b.c
return s==null?b.c=A.cU(a,b.x,!0):s},
cR(a,b){var s=b.c
return s==null?b.c=A.aN(a,"X",[b.x]):s},
di(a){var s=a.w
if(s===6||s===7||s===8)return A.di(a.x)
return s===12||s===13},
eC(a){return a.as},
dV(a){return A.by(v.typeUniverse,a,!1)},
N(a1,a2,a3,a4){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0=a2.w
switch(a0){case 5:case 1:case 2:case 3:case 4:return a2
case 6:s=a2.x
r=A.N(a1,s,a3,a4)
if(r===s)return a2
return A.dD(a1,r,!0)
case 7:s=a2.x
r=A.N(a1,s,a3,a4)
if(r===s)return a2
return A.cU(a1,r,!0)
case 8:s=a2.x
r=A.N(a1,s,a3,a4)
if(r===s)return a2
return A.dB(a1,r,!0)
case 9:q=a2.y
p=A.ab(a1,q,a3,a4)
if(p===q)return a2
return A.aN(a1,a2.x,p)
case 10:o=a2.x
n=A.N(a1,o,a3,a4)
m=a2.y
l=A.ab(a1,m,a3,a4)
if(n===o&&l===m)return a2
return A.cS(a1,n,l)
case 11:k=a2.x
j=a2.y
i=A.ab(a1,j,a3,a4)
if(i===j)return a2
return A.dC(a1,k,i)
case 12:h=a2.x
g=A.N(a1,h,a3,a4)
f=a2.y
e=A.fB(a1,f,a3,a4)
if(g===h&&e===f)return a2
return A.dA(a1,g,e)
case 13:d=a2.y
a4+=d.length
c=A.ab(a1,d,a3,a4)
o=a2.x
n=A.N(a1,o,a3,a4)
if(c===d&&n===o)return a2
return A.cT(a1,n,c,!0)
case 14:b=a2.x
if(b<a4)return a2
a=a3[b-a4]
if(a==null)return a2
return a
default:throw A.b(A.aX("Attempted to substitute unexpected RTI kind "+a0))}},
ab(a,b,c,d){var s,r,q,p,o=b.length,n=A.ct(o)
for(s=!1,r=0;r<o;++r){q=b[r]
p=A.N(a,q,c,d)
if(p!==q)s=!0
n[r]=p}return s?n:b},
fC(a,b,c,d){var s,r,q,p,o,n,m=b.length,l=A.ct(m)
for(s=!1,r=0;r<m;r+=3){q=b[r]
p=b[r+1]
o=b[r+2]
n=A.N(a,o,c,d)
if(n!==o)s=!0
l.splice(r,3,q,p,n)}return s?l:b},
fB(a,b,c,d){var s,r=b.a,q=A.ab(a,r,c,d),p=b.b,o=A.ab(a,p,c,d),n=b.c,m=A.fC(a,n,c,d)
if(q===r&&o===p&&m===n)return b
s=new A.bt()
s.a=q
s.b=o
s.c=m
return s},
bC(a,b){a[v.arrayRti]=b
return a},
dT(a){var s=a.$S
if(s!=null){if(typeof s=="number")return A.fQ(s)
return a.$S()}return null},
fU(a,b){var s
if(A.di(b))if(a instanceof A.Q){s=A.dT(a)
if(s!=null)return s}return A.ae(a)},
ae(a){if(a instanceof A.d)return A.a8(a)
if(Array.isArray(a))return A.cv(a)
return A.cV(J.ad(a))},
cv(a){var s=a[v.arrayRti],r=t.b
if(s==null)return r
if(s.constructor!==r.constructor)return r
return s},
a8(a){var s=a.$ti
return s!=null?s:A.cV(a)},
cV(a){var s=a.constructor,r=s.$ccache
if(r!=null)return r
return A.fg(a,s)},
fg(a,b){var s=a instanceof A.Q?Object.getPrototypeOf(Object.getPrototypeOf(a)).constructor:b,r=A.f1(v.typeUniverse,s.name)
b.$ccache=r
return r},
fQ(a){var s,r=v.types,q=r[a]
if(typeof q=="string"){s=A.by(v.typeUniverse,q,!1)
r[a]=s
return s}return q},
fP(a){return A.W(A.a8(a))},
fA(a){var s=a instanceof A.Q?A.dT(a):null
if(s!=null)return s
if(t.R.b(a))return J.ef(a).a
if(Array.isArray(a))return A.cv(a)
return A.ae(a)},
W(a){var s=a.r
return s==null?a.r=A.dG(a):s},
dG(a){var s,r,q=a.as,p=q.replace(/\*/g,"")
if(p===q)return a.r=new A.cr(a)
s=A.by(v.typeUniverse,p,!0)
r=s.r
return r==null?s.r=A.dG(s):r},
A(a){return A.W(A.by(v.typeUniverse,a,!1))},
ff(a){var s,r,q,p,o,n,m=this
if(m===t.K)return A.G(m,a,A.fm)
if(!A.I(m))s=m===t._
else s=!0
if(s)return A.G(m,a,A.fq)
s=m.w
if(s===7)return A.G(m,a,A.fd)
if(s===1)return A.G(m,a,A.dL)
r=s===6?m.x:m
q=r.w
if(q===8)return A.G(m,a,A.fi)
if(r===t.S)p=A.dK
else if(r===t.i||r===t.H)p=A.fl
else if(r===t.N)p=A.fo
else p=r===t.y?A.cy:null
if(p!=null)return A.G(m,a,p)
if(q===9){o=r.x
if(r.y.every(A.fV)){m.f="$i"+o
if(o==="eu")return A.G(m,a,A.fk)
return A.G(m,a,A.fp)}}else if(q===11){n=A.fN(r.x,r.y)
return A.G(m,a,n==null?A.dL:n)}return A.G(m,a,A.fb)},
G(a,b,c){a.b=c
return a.b(b)},
fe(a){var s,r=this,q=A.fa
if(!A.I(r))s=r===t._
else s=!0
if(s)q=A.f4
else if(r===t.K)q=A.f3
else{s=A.aR(r)
if(s)q=A.fc}r.a=q
return r.a(a)},
bz(a){var s=a.w,r=!0
if(!A.I(a))if(!(a===t._))if(!(a===t.A))if(s!==7)if(!(s===6&&A.bz(a.x)))r=s===8&&A.bz(a.x)||a===t.P||a===t.T
return r},
fb(a){var s=this
if(a==null)return A.bz(s)
return A.fW(v.typeUniverse,A.fU(a,s),s)},
fd(a){if(a==null)return!0
return this.x.b(a)},
fp(a){var s,r=this
if(a==null)return A.bz(r)
s=r.f
if(a instanceof A.d)return!!a[s]
return!!J.ad(a)[s]},
fk(a){var s,r=this
if(a==null)return A.bz(r)
if(typeof a!="object")return!1
if(Array.isArray(a))return!0
s=r.f
if(a instanceof A.d)return!!a[s]
return!!J.ad(a)[s]},
fa(a){var s=this
if(a==null){if(A.aR(s))return a}else if(s.b(a))return a
A.dH(a,s)},
fc(a){var s=this
if(a==null)return a
else if(s.b(a))return a
A.dH(a,s)},
dH(a,b){throw A.b(A.eS(A.dr(a,A.r(b,null))))},
dr(a,b){return A.bH(a)+": type '"+A.r(A.fA(a),null)+"' is not a subtype of type '"+b+"'"},
eS(a){return new A.aL("TypeError: "+a)},
q(a,b){return new A.aL("TypeError: "+A.dr(a,b))},
fi(a){var s=this,r=s.w===6?s.x:s
return r.x.b(a)||A.cR(v.typeUniverse,r).b(a)},
fm(a){return a!=null},
f3(a){if(a!=null)return a
throw A.b(A.q(a,"Object"))},
fq(a){return!0},
f4(a){return a},
dL(a){return!1},
cy(a){return!0===a||!1===a},
hl(a){if(!0===a)return!0
if(!1===a)return!1
throw A.b(A.q(a,"bool"))},
hn(a){if(!0===a)return!0
if(!1===a)return!1
if(a==null)return a
throw A.b(A.q(a,"bool"))},
hm(a){if(!0===a)return!0
if(!1===a)return!1
if(a==null)return a
throw A.b(A.q(a,"bool?"))},
ho(a){if(typeof a=="number")return a
throw A.b(A.q(a,"double"))},
hq(a){if(typeof a=="number")return a
if(a==null)return a
throw A.b(A.q(a,"double"))},
hp(a){if(typeof a=="number")return a
if(a==null)return a
throw A.b(A.q(a,"double?"))},
dK(a){return typeof a=="number"&&Math.floor(a)===a},
hr(a){if(typeof a=="number"&&Math.floor(a)===a)return a
throw A.b(A.q(a,"int"))},
ht(a){if(typeof a=="number"&&Math.floor(a)===a)return a
if(a==null)return a
throw A.b(A.q(a,"int"))},
hs(a){if(typeof a=="number"&&Math.floor(a)===a)return a
if(a==null)return a
throw A.b(A.q(a,"int?"))},
fl(a){return typeof a=="number"},
hu(a){if(typeof a=="number")return a
throw A.b(A.q(a,"num"))},
hw(a){if(typeof a=="number")return a
if(a==null)return a
throw A.b(A.q(a,"num"))},
hv(a){if(typeof a=="number")return a
if(a==null)return a
throw A.b(A.q(a,"num?"))},
fo(a){return typeof a=="string"},
hx(a){if(typeof a=="string")return a
throw A.b(A.q(a,"String"))},
hz(a){if(typeof a=="string")return a
if(a==null)return a
throw A.b(A.q(a,"String"))},
hy(a){if(typeof a=="string")return a
if(a==null)return a
throw A.b(A.q(a,"String?"))},
dP(a,b){var s,r,q
for(s="",r="",q=0;q<a.length;++q,r=", ")s+=r+A.r(a[q],b)
return s},
fv(a,b){var s,r,q,p,o,n,m=a.x,l=a.y
if(""===m)return"("+A.dP(l,b)+")"
s=l.length
r=m.split(",")
q=r.length-s
for(p="(",o="",n=0;n<s;++n,o=", "){p+=o
if(q===0)p+="{"
p+=A.r(l[n],b)
if(q>=0)p+=" "+r[q];++q}return p+"})"},
dI(a4,a5,a6){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2=", ",a3=null
if(a6!=null){s=a6.length
if(a5==null)a5=A.bC([],t.s)
else a3=a5.length
r=a5.length
for(q=s;q>0;--q)a5.push("T"+(r+q))
for(p=t.X,o=t._,n="<",m="",q=0;q<s;++q,m=a2){l=a5.length
k=l-1-q
if(!(k>=0))return A.z(a5,k)
n=B.q.ai(n+m,a5[k])
j=a6[q]
i=j.w
if(!(i===2||i===3||i===4||i===5||j===p))l=j===o
else l=!0
if(!l)n+=" extends "+A.r(j,a5)}n+=">"}else n=""
p=a4.x
h=a4.y
g=h.a
f=g.length
e=h.b
d=e.length
c=h.c
b=c.length
a=A.r(p,a5)
for(a0="",a1="",q=0;q<f;++q,a1=a2)a0+=a1+A.r(g[q],a5)
if(d>0){a0+=a1+"["
for(a1="",q=0;q<d;++q,a1=a2)a0+=a1+A.r(e[q],a5)
a0+="]"}if(b>0){a0+=a1+"{"
for(a1="",q=0;q<b;q+=3,a1=a2){a0+=a1
if(c[q+1])a0+="required "
a0+=A.r(c[q+2],a5)+" "+c[q]}a0+="}"}if(a3!=null){a5.toString
a5.length=a3}return n+"("+a0+") => "+a},
r(a,b){var s,r,q,p,o,n,m,l=a.w
if(l===5)return"erased"
if(l===2)return"dynamic"
if(l===3)return"void"
if(l===1)return"Never"
if(l===4)return"any"
if(l===6)return A.r(a.x,b)
if(l===7){s=a.x
r=A.r(s,b)
q=s.w
return(q===12||q===13?"("+r+")":r)+"?"}if(l===8)return"FutureOr<"+A.r(a.x,b)+">"
if(l===9){p=A.fD(a.x)
o=a.y
return o.length>0?p+("<"+A.dP(o,b)+">"):p}if(l===11)return A.fv(a,b)
if(l===12)return A.dI(a,b,null)
if(l===13)return A.dI(a.x,b,a.y)
if(l===14){n=a.x
m=b.length
n=m-1-n
if(!(n>=0&&n<m))return A.z(b,n)
return b[n]}return"?"},
fD(a){var s=v.mangledGlobalNames[a]
if(s!=null)return s
return"minified:"+a},
f2(a,b){var s=a.tR[b]
for(;typeof s=="string";)s=a.tR[s]
return s},
f1(a,b){var s,r,q,p,o,n=a.eT,m=n[b]
if(m==null)return A.by(a,b,!1)
else if(typeof m=="number"){s=m
r=A.aO(a,5,"#")
q=A.ct(s)
for(p=0;p<s;++p)q[p]=r
o=A.aN(a,b,q)
n[b]=o
return o}else return m},
f_(a,b){return A.dE(a.tR,b)},
eZ(a,b){return A.dE(a.eT,b)},
by(a,b,c){var s,r=a.eC,q=r.get(b)
if(q!=null)return q
s=A.dy(A.dw(a,null,b,c))
r.set(b,s)
return s},
cs(a,b,c){var s,r,q=b.z
if(q==null)q=b.z=new Map()
s=q.get(c)
if(s!=null)return s
r=A.dy(A.dw(a,b,c,!0))
q.set(c,r)
return r},
f0(a,b,c){var s,r,q,p=b.Q
if(p==null)p=b.Q=new Map()
s=c.as
r=p.get(s)
if(r!=null)return r
q=A.cS(a,b,c.w===10?c.y:[c])
p.set(s,q)
return q},
F(a,b){b.a=A.fe
b.b=A.ff
return b},
aO(a,b,c){var s,r,q=a.eC.get(c)
if(q!=null)return q
s=new A.w(null,null)
s.w=b
s.as=c
r=A.F(a,s)
a.eC.set(c,r)
return r},
dD(a,b,c){var s,r=b.as+"*",q=a.eC.get(r)
if(q!=null)return q
s=A.eX(a,b,r,c)
a.eC.set(r,s)
return s},
eX(a,b,c,d){var s,r,q
if(d){s=b.w
if(!A.I(b))r=b===t.P||b===t.T||s===7||s===6
else r=!0
if(r)return b}q=new A.w(null,null)
q.w=6
q.x=b
q.as=c
return A.F(a,q)},
cU(a,b,c){var s,r=b.as+"?",q=a.eC.get(r)
if(q!=null)return q
s=A.eW(a,b,r,c)
a.eC.set(r,s)
return s},
eW(a,b,c,d){var s,r,q,p
if(d){s=b.w
r=!0
if(!A.I(b))if(!(b===t.P||b===t.T))if(s!==7)r=s===8&&A.aR(b.x)
if(r)return b
else if(s===1||b===t.A)return t.P
else if(s===6){q=b.x
if(q.w===8&&A.aR(q.x))return q
else return A.dh(a,b)}}p=new A.w(null,null)
p.w=7
p.x=b
p.as=c
return A.F(a,p)},
dB(a,b,c){var s,r=b.as+"/",q=a.eC.get(r)
if(q!=null)return q
s=A.eU(a,b,r,c)
a.eC.set(r,s)
return s},
eU(a,b,c,d){var s,r
if(d){s=b.w
if(A.I(b)||b===t.K||b===t._)return b
else if(s===1)return A.aN(a,"X",[b])
else if(b===t.P||b===t.T)return t.W}r=new A.w(null,null)
r.w=8
r.x=b
r.as=c
return A.F(a,r)},
eY(a,b){var s,r,q=""+b+"^",p=a.eC.get(q)
if(p!=null)return p
s=new A.w(null,null)
s.w=14
s.x=b
s.as=q
r=A.F(a,s)
a.eC.set(q,r)
return r},
aM(a){var s,r,q,p=a.length
for(s="",r="",q=0;q<p;++q,r=",")s+=r+a[q].as
return s},
eT(a){var s,r,q,p,o,n=a.length
for(s="",r="",q=0;q<n;q+=3,r=","){p=a[q]
o=a[q+1]?"!":":"
s+=r+p+o+a[q+2].as}return s},
aN(a,b,c){var s,r,q,p=b
if(c.length>0)p+="<"+A.aM(c)+">"
s=a.eC.get(p)
if(s!=null)return s
r=new A.w(null,null)
r.w=9
r.x=b
r.y=c
if(c.length>0)r.c=c[0]
r.as=p
q=A.F(a,r)
a.eC.set(p,q)
return q},
cS(a,b,c){var s,r,q,p,o,n
if(b.w===10){s=b.x
r=b.y.concat(c)}else{r=c
s=b}q=s.as+(";<"+A.aM(r)+">")
p=a.eC.get(q)
if(p!=null)return p
o=new A.w(null,null)
o.w=10
o.x=s
o.y=r
o.as=q
n=A.F(a,o)
a.eC.set(q,n)
return n},
dC(a,b,c){var s,r,q="+"+(b+"("+A.aM(c)+")"),p=a.eC.get(q)
if(p!=null)return p
s=new A.w(null,null)
s.w=11
s.x=b
s.y=c
s.as=q
r=A.F(a,s)
a.eC.set(q,r)
return r},
dA(a,b,c){var s,r,q,p,o,n=b.as,m=c.a,l=m.length,k=c.b,j=k.length,i=c.c,h=i.length,g="("+A.aM(m)
if(j>0){s=l>0?",":""
g+=s+"["+A.aM(k)+"]"}if(h>0){s=l>0?",":""
g+=s+"{"+A.eT(i)+"}"}r=n+(g+")")
q=a.eC.get(r)
if(q!=null)return q
p=new A.w(null,null)
p.w=12
p.x=b
p.y=c
p.as=r
o=A.F(a,p)
a.eC.set(r,o)
return o},
cT(a,b,c,d){var s,r=b.as+("<"+A.aM(c)+">"),q=a.eC.get(r)
if(q!=null)return q
s=A.eV(a,b,c,r,d)
a.eC.set(r,s)
return s},
eV(a,b,c,d,e){var s,r,q,p,o,n,m,l
if(e){s=c.length
r=A.ct(s)
for(q=0,p=0;p<s;++p){o=c[p]
if(o.w===1){r[p]=o;++q}}if(q>0){n=A.N(a,b,r,0)
m=A.ab(a,c,r,0)
return A.cT(a,n,m,c!==m)}}l=new A.w(null,null)
l.w=13
l.x=b
l.y=c
l.as=d
return A.F(a,l)},
dw(a,b,c,d){return{u:a,e:b,r:c,s:[],p:0,n:d}},
dy(a){var s,r,q,p,o,n,m,l=a.r,k=a.s
for(s=l.length,r=0;r<s;){q=l.charCodeAt(r)
if(q>=48&&q<=57)r=A.eM(r+1,q,l,k)
else if((((q|32)>>>0)-97&65535)<26||q===95||q===36||q===124)r=A.dx(a,r,l,k,!1)
else if(q===46)r=A.dx(a,r,l,k,!0)
else{++r
switch(q){case 44:break
case 58:k.push(!1)
break
case 33:k.push(!0)
break
case 59:k.push(A.M(a.u,a.e,k.pop()))
break
case 94:k.push(A.eY(a.u,k.pop()))
break
case 35:k.push(A.aO(a.u,5,"#"))
break
case 64:k.push(A.aO(a.u,2,"@"))
break
case 126:k.push(A.aO(a.u,3,"~"))
break
case 60:k.push(a.p)
a.p=k.length
break
case 62:A.eO(a,k)
break
case 38:A.eN(a,k)
break
case 42:p=a.u
k.push(A.dD(p,A.M(p,a.e,k.pop()),a.n))
break
case 63:p=a.u
k.push(A.cU(p,A.M(p,a.e,k.pop()),a.n))
break
case 47:p=a.u
k.push(A.dB(p,A.M(p,a.e,k.pop()),a.n))
break
case 40:k.push(-3)
k.push(a.p)
a.p=k.length
break
case 41:A.eL(a,k)
break
case 91:k.push(a.p)
a.p=k.length
break
case 93:o=k.splice(a.p)
A.dz(a.u,a.e,o)
a.p=k.pop()
k.push(o)
k.push(-1)
break
case 123:k.push(a.p)
a.p=k.length
break
case 125:o=k.splice(a.p)
A.eQ(a.u,a.e,o)
a.p=k.pop()
k.push(o)
k.push(-2)
break
case 43:n=l.indexOf("(",r)
k.push(l.substring(r,n))
k.push(-4)
k.push(a.p)
a.p=k.length
r=n+1
break
default:throw"Bad character "+q}}}m=k.pop()
return A.M(a.u,a.e,m)},
eM(a,b,c,d){var s,r,q=b-48
for(s=c.length;a<s;++a){r=c.charCodeAt(a)
if(!(r>=48&&r<=57))break
q=q*10+(r-48)}d.push(q)
return a},
dx(a,b,c,d,e){var s,r,q,p,o,n,m=b+1
for(s=c.length;m<s;++m){r=c.charCodeAt(m)
if(r===46){if(e)break
e=!0}else{if(!((((r|32)>>>0)-97&65535)<26||r===95||r===36||r===124))q=r>=48&&r<=57
else q=!0
if(!q)break}}p=c.substring(b,m)
if(e){s=a.u
o=a.e
if(o.w===10)o=o.x
n=A.f2(s,o.x)[p]
if(n==null)A.aS('No "'+p+'" in "'+A.eC(o)+'"')
d.push(A.cs(s,o,n))}else d.push(p)
return m},
eO(a,b){var s,r=a.u,q=A.dv(a,b),p=b.pop()
if(typeof p=="string")b.push(A.aN(r,p,q))
else{s=A.M(r,a.e,p)
switch(s.w){case 12:b.push(A.cT(r,s,q,a.n))
break
default:b.push(A.cS(r,s,q))
break}}},
eL(a,b){var s,r,q,p=a.u,o=b.pop(),n=null,m=null
if(typeof o=="number")switch(o){case-1:n=b.pop()
break
case-2:m=b.pop()
break
default:b.push(o)
break}else b.push(o)
s=A.dv(a,b)
o=b.pop()
switch(o){case-3:o=b.pop()
if(n==null)n=p.sEA
if(m==null)m=p.sEA
r=A.M(p,a.e,o)
q=new A.bt()
q.a=s
q.b=n
q.c=m
b.push(A.dA(p,r,q))
return
case-4:b.push(A.dC(p,b.pop(),s))
return
default:throw A.b(A.aX("Unexpected state under `()`: "+A.o(o)))}},
eN(a,b){var s=b.pop()
if(0===s){b.push(A.aO(a.u,1,"0&"))
return}if(1===s){b.push(A.aO(a.u,4,"1&"))
return}throw A.b(A.aX("Unexpected extended operation "+A.o(s)))},
dv(a,b){var s=b.splice(a.p)
A.dz(a.u,a.e,s)
a.p=b.pop()
return s},
M(a,b,c){if(typeof c=="string")return A.aN(a,c,a.sEA)
else if(typeof c=="number"){b.toString
return A.eP(a,b,c)}else return c},
dz(a,b,c){var s,r=c.length
for(s=0;s<r;++s)c[s]=A.M(a,b,c[s])},
eQ(a,b,c){var s,r=c.length
for(s=2;s<r;s+=3)c[s]=A.M(a,b,c[s])},
eP(a,b,c){var s,r,q=b.w
if(q===10){if(c===0)return b.x
s=b.y
r=s.length
if(c<=r)return s[c-1]
c-=r
b=b.x
q=b.w}else if(c===0)return b
if(q!==9)throw A.b(A.aX("Indexed base must be an interface type"))
s=b.y
if(c<=s.length)return s[c-1]
throw A.b(A.aX("Bad index "+c+" for "+b.h(0)))},
fW(a,b,c){var s,r=b.d
if(r==null)r=b.d=new Map()
s=r.get(c)
if(s==null){s=A.k(a,b,null,c,null,!1)?1:0
r.set(c,s)}if(0===s)return!1
if(1===s)return!0
return!0},
k(a,b,c,d,e,f){var s,r,q,p,o,n,m,l,k,j,i
if(b===d)return!0
if(!A.I(d))s=d===t._
else s=!0
if(s)return!0
r=b.w
if(r===4)return!0
if(A.I(b))return!1
s=b.w
if(s===1)return!0
q=r===14
if(q)if(A.k(a,c[b.x],c,d,e,!1))return!0
p=d.w
s=b===t.P||b===t.T
if(s){if(p===8)return A.k(a,b,c,d.x,e,!1)
return d===t.P||d===t.T||p===7||p===6}if(d===t.K){if(r===8)return A.k(a,b.x,c,d,e,!1)
if(r===6)return A.k(a,b.x,c,d,e,!1)
return r!==7}if(r===6)return A.k(a,b.x,c,d,e,!1)
if(p===6){s=A.dh(a,d)
return A.k(a,b,c,s,e,!1)}if(r===8){if(!A.k(a,b.x,c,d,e,!1))return!1
return A.k(a,A.cR(a,b),c,d,e,!1)}if(r===7){s=A.k(a,t.P,c,d,e,!1)
return s&&A.k(a,b.x,c,d,e,!1)}if(p===8){if(A.k(a,b,c,d.x,e,!1))return!0
return A.k(a,b,c,A.cR(a,d),e,!1)}if(p===7){s=A.k(a,b,c,t.P,e,!1)
return s||A.k(a,b,c,d.x,e,!1)}if(q)return!1
s=r!==12
if((!s||r===13)&&d===t.Z)return!0
o=r===11
if(o&&d===t.L)return!0
if(p===13){if(b===t.g)return!0
if(r!==13)return!1
n=b.y
m=d.y
l=n.length
if(l!==m.length)return!1
c=c==null?n:n.concat(c)
e=e==null?m:m.concat(e)
for(k=0;k<l;++k){j=n[k]
i=m[k]
if(!A.k(a,j,c,i,e,!1)||!A.k(a,i,e,j,c,!1))return!1}return A.dJ(a,b.x,c,d.x,e,!1)}if(p===12){if(b===t.g)return!0
if(s)return!1
return A.dJ(a,b,c,d,e,!1)}if(r===9){if(p!==9)return!1
return A.fj(a,b,c,d,e,!1)}if(o&&p===11)return A.fn(a,b,c,d,e,!1)
return!1},
dJ(a3,a4,a5,a6,a7,a8){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2
if(!A.k(a3,a4.x,a5,a6.x,a7,!1))return!1
s=a4.y
r=a6.y
q=s.a
p=r.a
o=q.length
n=p.length
if(o>n)return!1
m=n-o
l=s.b
k=r.b
j=l.length
i=k.length
if(o+j<n+i)return!1
for(h=0;h<o;++h){g=q[h]
if(!A.k(a3,p[h],a7,g,a5,!1))return!1}for(h=0;h<m;++h){g=l[h]
if(!A.k(a3,p[o+h],a7,g,a5,!1))return!1}for(h=0;h<i;++h){g=l[m+h]
if(!A.k(a3,k[h],a7,g,a5,!1))return!1}f=s.c
e=r.c
d=f.length
c=e.length
for(b=0,a=0;a<c;a+=3){a0=e[a]
for(;!0;){if(b>=d)return!1
a1=f[b]
b+=3
if(a0<a1)return!1
a2=f[b-2]
if(a1<a0){if(a2)return!1
continue}g=e[a+1]
if(a2&&!g)return!1
g=f[b-1]
if(!A.k(a3,e[a+2],a7,g,a5,!1))return!1
break}}for(;b<d;){if(f[b+1])return!1
b+=3}return!0},
fj(a,b,c,d,e,f){var s,r,q,p,o,n=b.x,m=d.x
for(;n!==m;){s=a.tR[n]
if(s==null)return!1
if(typeof s=="string"){n=s
continue}r=s[m]
if(r==null)return!1
q=r.length
p=q>0?new Array(q):v.typeUniverse.sEA
for(o=0;o<q;++o)p[o]=A.cs(a,b,r[o])
return A.dF(a,p,null,c,d.y,e,!1)}return A.dF(a,b.y,null,c,d.y,e,!1)},
dF(a,b,c,d,e,f,g){var s,r=b.length
for(s=0;s<r;++s)if(!A.k(a,b[s],d,e[s],f,!1))return!1
return!0},
fn(a,b,c,d,e,f){var s,r=b.y,q=d.y,p=r.length
if(p!==q.length)return!1
if(b.x!==d.x)return!1
for(s=0;s<p;++s)if(!A.k(a,r[s],c,q[s],e,!1))return!1
return!0},
aR(a){var s=a.w,r=!0
if(!(a===t.P||a===t.T))if(!A.I(a))if(s!==7)if(!(s===6&&A.aR(a.x)))r=s===8&&A.aR(a.x)
return r},
fV(a){var s
if(!A.I(a))s=a===t._
else s=!0
return s},
I(a){var s=a.w
return s===2||s===3||s===4||s===5||a===t.X},
dE(a,b){var s,r,q=Object.keys(b),p=q.length
for(s=0;s<p;++s){r=q[s]
a[r]=b[r]}},
ct(a){return a>0?new Array(a):v.typeUniverse.sEA},
w:function w(a,b){var _=this
_.a=a
_.b=b
_.r=_.f=_.d=_.c=null
_.w=0
_.as=_.Q=_.z=_.y=_.x=null},
bt:function bt(){this.c=this.b=this.a=null},
cr:function cr(a){this.a=a},
bs:function bs(){},
aL:function aL(a){this.a=a},
eE(){var s,r,q={}
if(self.scheduleImmediate!=null)return A.fG()
if(self.MutationObserver!=null&&self.document!=null){s=self.document.createElement("div")
r=self.document.createElement("span")
q.a=null
new self.MutationObserver(A.cD(new A.c3(q),1)).observe(s,{childList:true})
return new A.c2(q,s,r)}else if(self.setImmediate!=null)return A.fH()
return A.fI()},
eF(a){self.scheduleImmediate(A.cD(new A.c4(a),0))},
eG(a){self.setImmediate(A.cD(new A.c5(a),0))},
eH(a){A.eR(0,a)},
eR(a,b){var s=new A.cp()
s.am(a,b)
return s},
fs(a){return new A.bn(new A.n($.i,a.i("n<0>")),a.i("bn<0>"))},
f7(a,b){a.$2(0,null)
b.b=!0
return b.a},
hA(a,b){A.f8(a,b)},
f6(a,b){var s,r=a==null?b.$ti.c.a(a):a
if(!b.b)b.a.a2(r)
else{s=b.a
if(b.$ti.i("X<1>").b(r))s.a4(r)
else s.L(r)}},
f5(a,b){var s=A.P(a),r=A.H(a),q=b.a
if(b.b)q.v(s,r)
else q.K(s,r)},
f8(a,b){var s,r,q=new A.cw(b),p=new A.cx(b)
if(a instanceof A.n)a.ac(q,p,t.z)
else{s=t.z
if(a instanceof A.n)a.Z(q,p,s)
else{r=new A.n($.i,t.d)
r.a=8
r.c=a
r.ac(q,p,s)}}},
fF(a){var s=function(b,c){return function(d,e){while(true){try{b(d,e)
break}catch(r){e=r
d=c}}}}(a,1)
return $.i.X(new A.cA(s))},
bD(a,b){var s=A.cC(a,"error",t.K)
return new A.aY(s,b==null?A.eh(a):b)},
eh(a){var s
if(t.Q.b(a)){s=a.gH()
if(s!=null)return s}return B.m},
ds(a,b){var s,r
for(;s=a.a,(s&4)!==0;)a=a.c
if(a===b){b.K(new A.y(!0,a,null,"Cannot complete a future with itself"),A.dj())
return}s|=b.a&1
a.a=s
if((s&24)!==0){r=b.C()
b.B(a)
A.a7(b,r)}else{r=b.c
b.aa(a)
a.T(r)}},
eJ(a,b){var s,r,q={},p=q.a=a
for(;s=p.a,(s&4)!==0;){p=p.c
q.a=p}if(p===b){b.K(new A.y(!0,p,null,"Cannot complete a future with itself"),A.dj())
return}if((s&24)===0){r=b.c
b.aa(p)
q.a.T(r)
return}if((s&16)===0&&b.c==null){b.B(p)
return}b.a^=2
A.aa(null,null,b.b,new A.ca(q,b))},
a7(a,b){var s,r,q,p,o,n,m,l,k,j,i,h,g={},f=g.a=a
for(;!0;){s={}
r=f.a
q=(r&16)===0
p=!q
if(b==null){if(p&&(r&1)===0){f=f.c
A.bA(f.a,f.b)}return}s.a=b
o=b.a
for(f=b;o!=null;f=o,o=n){f.a=null
A.a7(g.a,f)
s.a=o
n=o.a}r=g.a
m=r.c
s.b=p
s.c=m
if(q){l=f.c
l=(l&1)!==0||(l&15)===8}else l=!0
if(l){k=f.b.b
if(p){r=r.b===k
r=!(r||r)}else r=!1
if(r){A.bA(m.a,m.b)
return}j=$.i
if(j!==k)$.i=k
else j=null
f=f.c
if((f&15)===8)new A.ch(s,g,p).$0()
else if(q){if((f&1)!==0)new A.cg(s,m).$0()}else if((f&2)!==0)new A.cf(g,s).$0()
if(j!=null)$.i=j
f=s.c
if(f instanceof A.n){r=s.a.$ti
r=r.i("X<2>").b(f)||!r.y[1].b(f)}else r=!1
if(r){i=s.a.b
if((f.a&24)!==0){h=i.c
i.c=null
b=i.D(h)
i.a=f.a&30|i.a&1
i.c=f.c
g.a=f
continue}else A.ds(f,i)
return}}i=s.a.b
h=i.c
i.c=null
b=i.D(h)
f=s.b
r=s.c
if(!f){i.a=8
i.c=r}else{i.a=i.a&1|16
i.c=r}g.a=i
f=i}},
fw(a,b){if(t.C.b(a))return b.X(a)
if(t.v.b(a))return a
throw A.b(A.d8(a,"onError",u.c))},
ft(){var s,r
for(s=$.a9;s!=null;s=$.a9){$.aQ=null
r=s.b
$.a9=r
if(r==null)$.aP=null
s.a.$0()}},
fz(){$.cW=!0
try{A.ft()}finally{$.aQ=null
$.cW=!1
if($.a9!=null)$.d6().$1(A.dS())}},
dQ(a){var s=new A.bo(a),r=$.aP
if(r==null){$.a9=$.aP=s
if(!$.cW)$.d6().$1(A.dS())}else $.aP=r.b=s},
fy(a){var s,r,q,p=$.a9
if(p==null){A.dQ(a)
$.aQ=$.aP
return}s=new A.bo(a)
r=$.aQ
if(r==null){s.b=p
$.a9=$.aQ=s}else{q=r.b
s.b=q
$.aQ=r.b=s
if(q==null)$.aP=s}},
d4(a){var s=null,r=$.i
if(B.a===r){A.aa(s,s,B.a,a)
return}A.aa(s,s,r,r.ae(a))},
h9(a){A.cC(a,"stream",t.K)
return new A.bw()},
bB(a){return},
eI(a,b,c,d,e){var s=$.i,r=e?1:0,q=c!=null?32:0
A.dq(s,c)
return new A.a4(a,b,s,r|q)},
dq(a,b){if(b==null)b=A.fJ()
if(t.f.b(b))return a.X(b)
if(t.u.b(b))return b
throw A.b(A.aU("handleError callback must take either an Object (the error), or both an Object (the error) and a StackTrace.",null))},
fu(a,b){A.bA(a,b)},
bA(a,b){A.fy(new A.cz(a,b))},
dN(a,b,c,d){var s,r=$.i
if(r===c)return d.$0()
$.i=c
s=r
try{r=d.$0()
return r}finally{$.i=s}},
dO(a,b,c,d,e){var s,r=$.i
if(r===c)return d.$1(e)
$.i=c
s=r
try{r=d.$1(e)
return r}finally{$.i=s}},
fx(a,b,c,d,e,f){var s,r=$.i
if(r===c)return d.$2(e,f)
$.i=c
s=r
try{r=d.$2(e,f)
return r}finally{$.i=s}},
aa(a,b,c,d){if(B.a!==c)d=c.ae(d)
A.dQ(d)},
c3:function c3(a){this.a=a},
c2:function c2(a,b,c){this.a=a
this.b=b
this.c=c},
c4:function c4(a){this.a=a},
c5:function c5(a){this.a=a},
cp:function cp(){},
cq:function cq(a,b){this.a=a
this.b=b},
bn:function bn(a,b){this.a=a
this.b=!1
this.$ti=b},
cw:function cw(a){this.a=a},
cx:function cx(a){this.a=a},
cA:function cA(a){this.a=a},
aY:function aY(a,b){this.a=a
this.b=b},
ax:function ax(a,b){this.a=a
this.$ti=b},
ay:function ay(a,b,c,d){var _=this
_.ay=0
_.CW=_.ch=null
_.w=a
_.a=b
_.d=c
_.e=d
_.r=null},
a3:function a3(){},
aK:function aK(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.e=_.d=null
_.$ti=c},
co:function co(a,b){this.a=a
this.b=b},
a6:function a6(a,b,c,d,e){var _=this
_.a=null
_.b=a
_.c=b
_.d=c
_.e=d
_.$ti=e},
n:function n(a,b){var _=this
_.a=0
_.b=a
_.c=null
_.$ti=b},
c7:function c7(a,b){this.a=a
this.b=b},
ce:function ce(a,b){this.a=a
this.b=b},
cb:function cb(a){this.a=a},
cc:function cc(a){this.a=a},
cd:function cd(a,b,c){this.a=a
this.b=b
this.c=c},
ca:function ca(a,b){this.a=a
this.b=b},
c9:function c9(a,b){this.a=a
this.b=b},
c8:function c8(a,b,c){this.a=a
this.b=b
this.c=c},
ch:function ch(a,b,c){this.a=a
this.b=b
this.c=c},
ci:function ci(a){this.a=a},
cg:function cg(a,b){this.a=a
this.b=b},
cf:function cf(a,b){this.a=a
this.b=b},
bo:function bo(a){this.a=a
this.b=null},
a1:function a1(){},
bS:function bS(a,b){this.a=a
this.b=b},
bT:function bT(a,b){this.a=a
this.b=b},
bv:function bv(){},
cn:function cn(a){this.a=a},
bp:function bp(){},
a2:function a2(a,b,c,d){var _=this
_.a=null
_.b=0
_.d=a
_.e=b
_.f=c
_.$ti=d},
U:function U(a,b){this.a=a
this.$ti=b},
a4:function a4(a,b,c,d){var _=this
_.w=a
_.a=b
_.d=c
_.e=d
_.r=null},
T:function T(){},
aJ:function aJ(){},
br:function br(){},
a5:function a5(a){this.b=a
this.a=null},
aH:function aH(){this.a=0
this.c=this.b=null},
ck:function ck(a,b){this.a=a
this.b=b},
az:function az(a){this.a=1
this.b=a
this.c=null},
bw:function bw(){},
cu:function cu(){},
cz:function cz(a,b){this.a=a
this.b=b},
cl:function cl(){},
cm:function cm(a,b){this.a=a
this.b=b},
dt(a,b){var s=a[b]
return s===a?null:s},
du(a,b,c){if(c==null)a[b]=a
else a[b]=c},
eK(){var s=Object.create(null)
A.du(s,"<non-identifier-key>",s)
delete s["<non-identifier-key>"]
return s},
ew(a){var s,r={}
if(A.d0(a))return"{...}"
s=new A.bj("")
try{$.v.push(a)
s.a+="{"
r.a=!0
a.af(0,new A.bO(r,s))
s.a+="}"}finally{if(0>=$.v.length)return A.z($.v,-1)
$.v.pop()}r=s.a
return r.charCodeAt(0)==0?r:r},
aA:function aA(){},
aC:function aC(a){var _=this
_.a=0
_.e=_.d=_.c=_.b=null
_.$ti=a},
aB:function aB(a,b){this.a=a
this.$ti=b},
bu:function bu(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
h:function h(){},
a_:function a_(){},
bO:function bO(a,b){this.a=a
this.b=b},
ep(a,b){a=A.b(a)
a.stack=b.h(0)
throw a
throw A.b("unreachable")},
ev(a,b,c){var s
if(a>4294967295)A.aS(A.eB(a,0,4294967295,"length",null))
s=J.df(A.bC(new Array(a),c.i("t<0>")))
return s},
dl(a,b,c){var s=J.ee(b)
if(!s.l())return a
if(c.length===0){do a+=A.o(s.gm())
while(s.l())}else{a+=A.o(s.gm())
for(;s.l();)a=a+c+A.o(s.gm())}return a},
dj(){return A.H(new Error())},
bH(a){if(typeof a=="number"||A.cy(a)||a==null)return J.aT(a)
if(typeof a=="string")return JSON.stringify(a)
return A.eA(a)},
eq(a,b){A.cC(a,"error",t.K)
A.cC(b,"stackTrace",t.l)
A.ep(a,b)},
aX(a){return new A.aW(a)},
aU(a,b){return new A.y(!1,null,b,a)},
d8(a,b,c){return new A.y(!0,a,b,c)},
eB(a,b,c,d,e){return new A.au(b,c,!0,a,d,"Invalid value")},
er(a,b,c,d){return new A.b0(b,!0,a,d,"Index out of range")},
dp(a){return new A.bm(a)},
dn(a){return new A.bk(a)},
dk(a){return new A.C(a)},
bG(a){return new A.b_(a)},
es(a,b,c){var s,r
if(A.d0(a)){if(b==="("&&c===")")return"(...)"
return b+"..."+c}s=A.bC([],t.s)
$.v.push(a)
try{A.fr(a,s)}finally{if(0>=$.v.length)return A.z($.v,-1)
$.v.pop()}r=A.dl(b,s,", ")+c
return r.charCodeAt(0)==0?r:r},
de(a,b,c){var s,r
if(A.d0(a))return b+"..."+c
s=new A.bj(b)
$.v.push(a)
try{r=s
r.a=A.dl(r.a,a,", ")}finally{if(0>=$.v.length)return A.z($.v,-1)
$.v.pop()}s.a+=c
r=s.a
return r.charCodeAt(0)==0?r:r},
fr(a,b){var s,r,q,p,o,n,m,l=a.gq(a),k=0,j=0
while(!0){if(!(k<80||j<3))break
if(!l.l())return
s=A.o(l.gm())
b.push(s)
k+=s.length+2;++j}if(!l.l()){if(j<=5)return
if(0>=b.length)return A.z(b,-1)
r=b.pop()
if(0>=b.length)return A.z(b,-1)
q=b.pop()}else{p=l.gm();++j
if(!l.l()){if(j<=4){b.push(A.o(p))
return}r=A.o(p)
if(0>=b.length)return A.z(b,-1)
q=b.pop()
k+=r.length+2}else{o=l.gm();++j
for(;l.l();p=o,o=n){n=l.gm();++j
if(j>100){while(!0){if(!(k>75&&j>3))break
if(0>=b.length)return A.z(b,-1)
k-=b.pop().length+2;--j}b.push("...")
return}}q=A.o(p)
r=A.o(o)
k+=r.length+q.length+4}}if(j>b.length+2){k+=5
m="..."}else m=null
while(!0){if(!(k>80&&b.length>3))break
if(0>=b.length)return A.z(b,-1)
k-=b.pop().length+2
if(m==null){k+=5
m="..."}}if(m!=null)b.push(m)
b.push(q)
b.push(r)},
j:function j(){},
aW:function aW(a){this.a=a},
D:function D(){},
y:function y(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
au:function au(a,b,c,d,e,f){var _=this
_.e=a
_.f=b
_.a=c
_.b=d
_.c=e
_.d=f},
b0:function b0(a,b,c,d,e){var _=this
_.f=a
_.a=b
_.b=c
_.c=d
_.d=e},
bm:function bm(a){this.a=a},
bk:function bk(a){this.a=a},
C:function C(a){this.a=a},
b_:function b_(a){this.a=a},
av:function av(){},
c6:function c6(a){this.a=a},
c:function c(){},
p:function p(){},
d:function d(){},
bx:function bx(){},
bj:function bj(a){this.a=a},
f9(a,b,c){if(c>=1)return a.$1(b)
return a.$0()},
dM(a){return a==null||A.cy(a)||typeof a=="number"||typeof a=="string"||t.U.b(a)||t.E.b(a)||t.e.b(a)||t.O.b(a)||t.D.b(a)||t.k.b(a)||t.w.b(a)||t.B.b(a)||t.q.b(a)||t.J.b(a)||t.Y.b(a)},
fX(a){if(A.dM(a))return a
return new A.cJ(new A.aC(t.F)).$1(a)},
cJ:function cJ(a){this.a=a},
fL(a,b,c,d,e){var s,r=e.i("aK<0>"),q=new A.aK(null,null,r),p=new A.cB(q,c,d)
if(typeof p=="function")A.aS(A.aU("Attempting to rewrap a JS function.",null))
s=function(f,g){return function(h){return f(g,h,arguments.length)}}(A.f9,p)
s[$.d5()]=p
a[b]=s
return new A.ax(q,r.i("ax<1>"))},
eD(){var s=new A.c0()
s.al()
return s},
d1(){var s=0,r=A.fs(t.n),q,p
var $async$d1=A.fF(function(a,b){if(a===1)return A.f5(b,r)
while(true)switch(s){case 0:q=A.eD()
p=q.a
p===$&&A.e1()
new A.U(p,A.a8(p).i("U<1>")).aK(new A.cK(q))
return A.f6(null,r)}})
return A.f7($async$d1,r)},
cB:function cB(a,b,c){this.a=a
this.b=b
this.c=c},
c0:function c0(){this.a=$},
c1:function c1(a){this.a=a},
cK:function cK(a){this.a=a},
h0(a){if(typeof dartPrint=="function"){dartPrint(a)
return}if(typeof console=="object"&&typeof console.log!="undefined"){console.log(a)
return}if(typeof print=="function"){print(a)
return}throw"Unable to print message: "+String(a)},
h3(a){A.e0(new A.an("Field '"+a+"' has been assigned during initialization."),new Error())},
e1(){A.e0(new A.an("Field '' has not been initialized."),new Error())},
et(a,b,c,d,e,f){var s
if(c==null)return a[b]()
else{s=a[b](c)
return s}}},B={}
var w=[A,J,B]
var $={}
A.cP.prototype={}
J.b1.prototype={
gn(a){return A.at(a)},
h(a){return"Instance of '"+A.bQ(a)+"'"},
gk(a){return A.W(A.cV(this))}}
J.b2.prototype={
h(a){return String(a)},
gn(a){return a?519018:218159},
gk(a){return A.W(t.y)},
$if:1}
J.aj.prototype={
h(a){return"null"},
gn(a){return 0},
$if:1,
$ip:1}
J.al.prototype={$im:1}
J.K.prototype={
gn(a){return 0},
h(a){return String(a)}}
J.bh.prototype={}
J.aw.prototype={}
J.J.prototype={
h(a){var s=a[$.d5()]
if(s==null)return this.aj(a)
return"JavaScript function for "+J.aT(s)}}
J.ak.prototype={
gn(a){return 0},
h(a){return String(a)}}
J.am.prototype={
gn(a){return 0},
h(a){return String(a)}}
J.t.prototype={
aH(a,b){var s
if(!!a.fixed$length)A.aS(A.dp("addAll"))
for(s=b.gq(b);s.l();)a.push(s.gm())},
F(a,b,c){return new A.B(a,b,A.cv(a).i("@<1>").u(c).i("B<1,2>"))},
E(a,b){if(!(b<a.length))return A.z(a,b)
return a[b]},
h(a){return A.de(a,"[","]")},
gq(a){return new J.aV(a,a.length,A.cv(a).i("aV<1>"))},
gn(a){return A.at(a)},
gj(a){return a.length},
$ie:1,
$ic:1}
J.bN.prototype={}
J.aV.prototype={
gm(){var s=this.d
return s==null?this.$ti.c.a(s):s},
l(){var s,r=this,q=r.a,p=q.length
if(r.b!==p)throw A.b(A.h2(q))
s=r.c
if(s>=p){r.d=null
return!1}r.d=q[s]
r.c=s+1
return!0}}
J.b4.prototype={
h(a){if(a===0&&1/a<0)return"-0.0"
else return""+a},
gn(a){var s,r,q,p,o=a|0
if(a===o)return o&536870911
s=Math.abs(a)
r=Math.log(s)/0.6931471805599453|0
q=Math.pow(2,r)
p=s<1?s/q:q/s
return((p*9007199254740992|0)+(p*3542243181176521|0))*599197+r*1259&536870911},
aF(a,b){var s
if(a>0)s=this.aE(a,b)
else{s=b>31?31:b
s=a>>s>>>0}return s},
aE(a,b){return b>31?0:a>>>b},
gk(a){return A.W(t.H)},
$il:1}
J.ai.prototype={
gk(a){return A.W(t.S)},
$if:1,
$ia:1}
J.b3.prototype={
gk(a){return A.W(t.i)},
$if:1}
J.Y.prototype={
ai(a,b){return a+b},
h(a){return a},
gn(a){var s,r,q
for(s=a.length,r=0,q=0;q<s;++q){r=r+a.charCodeAt(q)&536870911
r=r+((r&524287)<<10)&536870911
r^=r>>6}r=r+((r&67108863)<<3)&536870911
r^=r>>11
return r+((r&16383)<<15)&536870911},
gk(a){return A.W(t.N)},
gj(a){return a.length},
$if:1,
$iS:1}
A.an.prototype={
h(a){return"LateInitializationError: "+this.a}}
A.e.prototype={}
A.L.prototype={
gq(a){return new A.Z(this,this.gj(0),this.$ti.i("Z<L.E>"))},
F(a,b,c){return new A.B(this,b,this.$ti.i("@<L.E>").u(c).i("B<1,2>"))}}
A.Z.prototype={
gm(){var s=this.d
return s==null?this.$ti.c.a(s):s},
l(){var s,r=this,q=r.a,p=J.dW(q),o=p.gj(q)
if(r.b!==o)throw A.b(A.bG(q))
s=r.c
if(s>=o){r.d=null
return!1}r.d=p.E(q,s);++r.c
return!0}}
A.R.prototype={
gq(a){var s=this.a
return new A.b6(s.gq(s),this.b,A.a8(this).i("b6<1,2>"))},
gj(a){var s=this.a
return s.gj(s)}}
A.af.prototype={$ie:1}
A.b6.prototype={
l(){var s=this,r=s.b
if(r.l()){s.a=s.c.$1(r.gm())
return!0}s.a=null
return!1},
gm(){var s=this.a
return s==null?this.$ti.y[1].a(s):s}}
A.B.prototype={
gj(a){return J.cM(this.a)},
E(a,b){return this.b.$1(J.ed(this.a,b))}}
A.ah.prototype={}
A.bV.prototype={
t(a){var s,r,q=this,p=new RegExp(q.a).exec(a)
if(p==null)return null
s=Object.create(null)
r=q.b
if(r!==-1)s.arguments=p[r+1]
r=q.c
if(r!==-1)s.argumentsExpr=p[r+1]
r=q.d
if(r!==-1)s.expr=p[r+1]
r=q.e
if(r!==-1)s.method=p[r+1]
r=q.f
if(r!==-1)s.receiver=p[r+1]
return s}}
A.as.prototype={
h(a){return"Null check operator used on a null value"}}
A.b5.prototype={
h(a){var s,r=this,q="NoSuchMethodError: method not found: '",p=r.b
if(p==null)return"NoSuchMethodError: "+r.a
s=r.c
if(s==null)return q+p+"' ("+r.a+")"
return q+p+"' on '"+s+"' ("+r.a+")"}}
A.bl.prototype={
h(a){var s=this.a
return s.length===0?"Error":"Error: "+s}}
A.bP.prototype={
h(a){return"Throw of null ('"+(this.a===null?"null":"undefined")+"' from JavaScript)"}}
A.ag.prototype={}
A.aI.prototype={
h(a){var s,r=this.b
if(r!=null)return r
r=this.a
s=r!==null&&typeof r==="object"?r.stack:null
return this.b=s==null?"":s},
$ix:1}
A.Q.prototype={
h(a){var s=this.constructor,r=s==null?null:s.name
return"Closure '"+A.e2(r==null?"unknown":r)+"'"},
gaW(){return this},
$C:"$1",
$R:1,
$D:null}
A.bE.prototype={$C:"$0",$R:0}
A.bF.prototype={$C:"$2",$R:2}
A.bU.prototype={}
A.bR.prototype={
h(a){var s=this.$static_name
if(s==null)return"Closure of unknown static method"
return"Closure '"+A.e2(s)+"'"}}
A.aZ.prototype={
gn(a){return(A.d3(this.a)^A.at(this.$_target))>>>0},
h(a){return"Closure '"+this.$_name+"' of "+("Instance of '"+A.bQ(this.a)+"'")}}
A.bq.prototype={
h(a){return"Reading static variable '"+this.a+"' during its initialization"}}
A.bi.prototype={
h(a){return"RuntimeError: "+this.a}}
A.cF.prototype={
$1(a){return this.a(a)},
$S:6}
A.cG.prototype={
$2(a,b){return this.a(a,b)},
$S:7}
A.cH.prototype={
$1(a){return this.a(a)},
$S:8}
A.b7.prototype={
gk(a){return B.u},
$if:1,
$icN:1}
A.aq.prototype={}
A.b8.prototype={
gk(a){return B.v},
$if:1,
$icO:1}
A.a0.prototype={
gj(a){return a.length},
$iu:1}
A.ao.prototype={
p(a,b){A.V(b,a,a.length)
return a[b]},
$ie:1,
$ic:1}
A.ap.prototype={$ie:1,$ic:1}
A.b9.prototype={
gk(a){return B.w},
$if:1,
$ibI:1}
A.ba.prototype={
gk(a){return B.x},
$if:1,
$ibJ:1}
A.bb.prototype={
gk(a){return B.y},
p(a,b){A.V(b,a,a.length)
return a[b]},
$if:1,
$ibK:1}
A.bc.prototype={
gk(a){return B.z},
p(a,b){A.V(b,a,a.length)
return a[b]},
$if:1,
$ibL:1}
A.bd.prototype={
gk(a){return B.A},
p(a,b){A.V(b,a,a.length)
return a[b]},
$if:1,
$ibM:1}
A.be.prototype={
gk(a){return B.B},
p(a,b){A.V(b,a,a.length)
return a[b]},
$if:1,
$ibX:1}
A.bf.prototype={
gk(a){return B.C},
p(a,b){A.V(b,a,a.length)
return a[b]},
$if:1,
$ibY:1}
A.ar.prototype={
gk(a){return B.D},
gj(a){return a.length},
p(a,b){A.V(b,a,a.length)
return a[b]},
$if:1,
$ibZ:1}
A.bg.prototype={
gk(a){return B.E},
gj(a){return a.length},
p(a,b){A.V(b,a,a.length)
return a[b]},
$if:1,
$ic_:1}
A.aD.prototype={}
A.aE.prototype={}
A.aF.prototype={}
A.aG.prototype={}
A.w.prototype={
i(a){return A.cs(v.typeUniverse,this,a)},
u(a){return A.f0(v.typeUniverse,this,a)}}
A.bt.prototype={}
A.cr.prototype={
h(a){return A.r(this.a,null)}}
A.bs.prototype={
h(a){return this.a}}
A.aL.prototype={$iD:1}
A.c3.prototype={
$1(a){var s=this.a,r=s.a
s.a=null
r.$0()},
$S:2}
A.c2.prototype={
$1(a){var s,r
this.a.a=a
s=this.b
r=this.c
s.firstChild?s.removeChild(r):s.appendChild(r)},
$S:9}
A.c4.prototype={
$0(){this.a.$0()},
$S:3}
A.c5.prototype={
$0(){this.a.$0()},
$S:3}
A.cp.prototype={
am(a,b){if(self.setTimeout!=null)self.setTimeout(A.cD(new A.cq(this,b),0),a)
else throw A.b(A.dp("`setTimeout()` not found."))}}
A.cq.prototype={
$0(){this.b.$0()},
$S:0}
A.bn.prototype={}
A.cw.prototype={
$1(a){return this.a.$2(0,a)},
$S:4}
A.cx.prototype={
$2(a,b){this.a.$2(1,new A.ag(a,b))},
$S:10}
A.cA.prototype={
$2(a,b){this.a(a,b)},
$S:11}
A.aY.prototype={
h(a){return A.o(this.a)},
$ij:1,
gH(){return this.b}}
A.ax.prototype={}
A.ay.prototype={
R(){},
S(){}}
A.a3.prototype={
gP(){return this.c<4},
ab(a,b,c,d){var s,r,q,p,o,n=this
if((n.c&4)!==0){s=new A.az($.i)
A.d4(s.gaz())
if(c!=null)s.c=c
return s}s=$.i
r=d?1:0
q=b!=null?32:0
A.dq(s,b)
p=new A.ay(n,a,s,r|q)
p.CW=p
p.ch=p
p.ay=n.c&1
o=n.e
n.e=p
p.ch=null
p.CW=o
if(o==null)n.d=p
else o.ch=p
if(n.d===p)A.bB(n.a)
return p},
a8(a){},
a9(a){},
I(){if((this.c&4)!==0)return new A.C("Cannot add new events after calling close")
return new A.C("Cannot add new events while doing an addStream")},
av(a){var s,r,q,p,o=this,n=o.c
if((n&2)!==0)throw A.b(A.dk(u.g))
s=o.d
if(s==null)return
r=n&1
o.c=n^3
for(;s!=null;){n=s.ay
if((n&1)===r){s.ay=n|2
a.$1(s)
n=s.ay^=1
q=s.ch
if((n&4)!==0){p=s.CW
if(p==null)o.d=q
else p.ch=q
if(q==null)o.e=p
else q.CW=p
s.CW=s
s.ch=s}s.ay=n&4294967293
s=q}else s=s.ch}o.c&=4294967293
if(o.d==null)o.a3()},
a3(){if((this.c&4)!==0)if(null.gaX())null.a2(null)
A.bB(this.b)}}
A.aK.prototype={
gP(){return A.a3.prototype.gP.call(this)&&(this.c&2)===0},
I(){if((this.c&2)!==0)return new A.C(u.g)
return this.ak()},
A(a){var s=this,r=s.d
if(r==null)return
if(r===s.e){s.c|=2
r.a0(a)
s.c&=4294967293
if(s.d==null)s.a3()
return}s.av(new A.co(s,a))}}
A.co.prototype={
$1(a){a.a0(this.b)},
$S(){return this.a.$ti.i("~(T<1>)")}}
A.a6.prototype={
aL(a){if((this.c&15)!==6)return!0
return this.b.b.Y(this.d,a.a)},
aJ(a){var s,r=this.e,q=null,p=a.a,o=this.b.b
if(t.C.b(r))q=o.aQ(r,p,a.b)
else q=o.Y(r,p)
try{p=q
return p}catch(s){if(t.c.b(A.P(s))){if((this.c&1)!==0)throw A.b(A.aU("The error handler of Future.then must return a value of the returned future's type","onError"))
throw A.b(A.aU("The error handler of Future.catchError must return a value of the future's type","onError"))}else throw s}}}
A.n.prototype={
aa(a){this.a=this.a&1|4
this.c=a},
Z(a,b,c){var s,r,q=$.i
if(q===B.a){if(b!=null&&!t.C.b(b)&&!t.v.b(b))throw A.b(A.d8(b,"onError",u.c))}else if(b!=null)b=A.fw(b,q)
s=new A.n(q,c.i("n<0>"))
r=b==null?1:3
this.J(new A.a6(s,r,a,b,this.$ti.i("@<1>").u(c).i("a6<1,2>")))
return s},
aV(a,b){return this.Z(a,null,b)},
ac(a,b,c){var s=new A.n($.i,c.i("n<0>"))
this.J(new A.a6(s,19,a,b,this.$ti.i("@<1>").u(c).i("a6<1,2>")))
return s},
aC(a){this.a=this.a&1|16
this.c=a},
B(a){this.a=a.a&30|this.a&1
this.c=a.c},
J(a){var s=this,r=s.a
if(r<=3){a.a=s.c
s.c=a}else{if((r&4)!==0){r=s.c
if((r.a&24)===0){r.J(a)
return}s.B(r)}A.aa(null,null,s.b,new A.c7(s,a))}},
T(a){var s,r,q,p,o,n=this,m={}
m.a=a
if(a==null)return
s=n.a
if(s<=3){r=n.c
n.c=a
if(r!=null){q=a.a
for(p=a;q!=null;p=q,q=o)o=q.a
p.a=r}}else{if((s&4)!==0){s=n.c
if((s.a&24)===0){s.T(a)
return}n.B(s)}m.a=n.D(a)
A.aa(null,null,n.b,new A.ce(m,n))}},
C(){var s=this.c
this.c=null
return this.D(s)},
D(a){var s,r,q
for(s=a,r=null;s!=null;r=s,s=q){q=s.a
s.a=r}return r},
ap(a){var s,r,q,p=this
p.a^=2
try{a.Z(new A.cb(p),new A.cc(p),t.P)}catch(q){s=A.P(q)
r=A.H(q)
A.d4(new A.cd(p,s,r))}},
L(a){var s=this,r=s.C()
s.a=8
s.c=a
A.a7(s,r)},
v(a,b){var s=this.C()
this.aC(A.bD(a,b))
A.a7(this,s)},
a2(a){if(this.$ti.i("X<1>").b(a)){this.a4(a)
return}this.an(a)},
an(a){this.a^=2
A.aa(null,null,this.b,new A.c9(this,a))},
a4(a){if(this.$ti.b(a)){A.eJ(a,this)
return}this.ap(a)},
K(a,b){this.a^=2
A.aa(null,null,this.b,new A.c8(this,a,b))},
$iX:1}
A.c7.prototype={
$0(){A.a7(this.a,this.b)},
$S:0}
A.ce.prototype={
$0(){A.a7(this.b,this.a.a)},
$S:0}
A.cb.prototype={
$1(a){var s,r,q,p=this.a
p.a^=2
try{p.L(p.$ti.c.a(a))}catch(q){s=A.P(q)
r=A.H(q)
p.v(s,r)}},
$S:2}
A.cc.prototype={
$2(a,b){this.a.v(a,b)},
$S:12}
A.cd.prototype={
$0(){this.a.v(this.b,this.c)},
$S:0}
A.ca.prototype={
$0(){A.ds(this.a.a,this.b)},
$S:0}
A.c9.prototype={
$0(){this.a.L(this.b)},
$S:0}
A.c8.prototype={
$0(){this.a.v(this.b,this.c)},
$S:0}
A.ch.prototype={
$0(){var s,r,q,p,o,n,m=this,l=null
try{q=m.a.a
l=q.b.b.aO(q.d)}catch(p){s=A.P(p)
r=A.H(p)
q=m.c&&m.b.a.c.a===s
o=m.a
if(q)o.c=m.b.a.c
else o.c=A.bD(s,r)
o.b=!0
return}if(l instanceof A.n&&(l.a&24)!==0){if((l.a&16)!==0){q=m.a
q.c=l.c
q.b=!0}return}if(l instanceof A.n){n=m.b.a
q=m.a
q.c=l.aV(new A.ci(n),t.z)
q.b=!1}},
$S:0}
A.ci.prototype={
$1(a){return this.a},
$S:13}
A.cg.prototype={
$0(){var s,r,q,p,o
try{q=this.a
p=q.a
q.c=p.b.b.Y(p.d,this.b)}catch(o){s=A.P(o)
r=A.H(o)
q=this.a
q.c=A.bD(s,r)
q.b=!0}},
$S:0}
A.cf.prototype={
$0(){var s,r,q,p,o,n,m=this
try{s=m.a.a.c
p=m.b
if(p.a.aL(s)&&p.a.e!=null){p.c=p.a.aJ(s)
p.b=!1}}catch(o){r=A.P(o)
q=A.H(o)
p=m.a.a.c
n=m.b
if(p.a===r)n.c=p
else n.c=A.bD(r,q)
n.b=!0}},
$S:0}
A.bo.prototype={}
A.a1.prototype={
gj(a){var s={},r=new A.n($.i,t.a)
s.a=0
this.ag(new A.bS(s,this),!0,new A.bT(s,r),r.gaq())
return r}}
A.bS.prototype={
$1(a){++this.a.a},
$S(){return A.a8(this.b).i("~(1)")}}
A.bT.prototype={
$0(){var s=this.b,r=this.a.a,q=s.C()
s.a=8
s.c=r
A.a7(s,q)},
$S:0}
A.bv.prototype={
gaB(){if((this.b&8)===0)return this.a
return this.a.gU()},
au(){var s,r=this
if((r.b&8)===0){s=r.a
return s==null?r.a=new A.aH():s}s=r.a.gU()
return s},
gaG(){var s=this.a
return(this.b&8)!==0?s.gU():s},
ao(){if((this.b&4)!==0)return new A.C("Cannot add event after closing")
return new A.C("Cannot add event while adding a stream")},
ab(a,b,c,d){var s,r,q,p,o=this
if((o.b&3)!==0)throw A.b(A.dk("Stream has already been listened to."))
s=A.eI(o,a,b,c,d)
r=o.gaB()
q=o.b|=1
if((q&8)!==0){p=o.a
p.sU(s)
p.aN()}else o.a=s
s.aD(r)
q=s.e
s.e=q|64
new A.cn(o).$0()
s.e&=4294967231
s.a5((q&4)!==0)
return s},
a8(a){if((this.b&8)!==0)this.a.aY()
A.bB(this.e)},
a9(a){if((this.b&8)!==0)this.a.aN()
A.bB(this.f)}}
A.cn.prototype={
$0(){A.bB(this.a.d)},
$S:0}
A.bp.prototype={
A(a){this.gaG().a1(new A.a5(a))}}
A.a2.prototype={}
A.U.prototype={
gn(a){return(A.at(this.a)^892482866)>>>0}}
A.a4.prototype={
R(){this.w.a8(this)},
S(){this.w.a9(this)}}
A.T.prototype={
aD(a){if(a==null)return
this.r=a
if(a.c!=null){this.e|=128
a.G(this)}},
a0(a){var s=this.e
if((s&8)!==0)return
if(s<64)this.A(a)
else this.a1(new A.a5(a))},
R(){},
S(){},
a1(a){var s,r=this,q=r.r
if(q==null)q=r.r=new A.aH()
q.ad(0,a)
s=r.e
if((s&128)===0){s|=128
r.e=s
if(s<256)q.G(r)}},
A(a){var s=this,r=s.e
s.e=r|64
s.d.aU(s.a,a)
s.e&=4294967231
s.a5((r&4)!==0)},
a5(a){var s,r,q=this,p=q.e
if((p&128)!==0&&q.r.c==null){p=q.e=p&4294967167
s=!1
if((p&4)!==0)if(p<256){s=q.r
s=s==null?null:s.c==null
s=s!==!1}if(s){p&=4294967291
q.e=p}}for(;!0;a=r){if((p&8)!==0){q.r=null
return}r=(p&4)!==0
if(a===r)break
q.e=p^64
if(r)q.R()
else q.S()
p=q.e&=4294967231}if((p&128)!==0&&p<256)q.r.G(q)}}
A.aJ.prototype={
ag(a,b,c,d){return this.a.ab(a,d,c,b===!0)},
aK(a){return this.ag(a,null,null,null)}}
A.br.prototype={}
A.a5.prototype={}
A.aH.prototype={
G(a){var s=this,r=s.a
if(r===1)return
if(r>=1){s.a=1
return}A.d4(new A.ck(s,a))
s.a=1},
ad(a,b){var s=this,r=s.c
if(r==null)s.b=s.c=b
else s.c=r.a=b}}
A.ck.prototype={
$0(){var s,r,q=this.a,p=q.a
q.a=0
if(p===3)return
s=q.b
r=s.a
q.b=r
if(r==null)q.c=null
this.b.A(s.b)},
$S:0}
A.az.prototype={
aA(){var s,r=this,q=r.a-1
if(q===0){r.a=-1
s=r.c
if(s!=null){r.c=null
r.b.ah(s)}}else r.a=q}}
A.bw.prototype={}
A.cu.prototype={}
A.cz.prototype={
$0(){A.eq(this.a,this.b)},
$S:0}
A.cl.prototype={
ah(a){var s,r,q
try{if(B.a===$.i){a.$0()
return}A.dN(null,null,this,a)}catch(q){s=A.P(q)
r=A.H(q)
A.bA(s,r)}},
aT(a,b){var s,r,q
try{if(B.a===$.i){a.$1(b)
return}A.dO(null,null,this,a,b)}catch(q){s=A.P(q)
r=A.H(q)
A.bA(s,r)}},
aU(a,b){return this.aT(a,b,t.z)},
ae(a){return new A.cm(this,a)},
aP(a){if($.i===B.a)return a.$0()
return A.dN(null,null,this,a)},
aO(a){return this.aP(a,t.z)},
aS(a,b){if($.i===B.a)return a.$1(b)
return A.dO(null,null,this,a,b)},
Y(a,b){var s=t.z
return this.aS(a,b,s,s)},
aR(a,b,c){if($.i===B.a)return a.$2(b,c)
return A.fx(null,null,this,a,b,c)},
aQ(a,b,c){var s=t.z
return this.aR(a,b,c,s,s,s)},
aM(a){return a},
X(a){var s=t.z
return this.aM(a,s,s,s)}}
A.cm.prototype={
$0(){return this.a.ah(this.b)},
$S:0}
A.aA.prototype={
gj(a){return this.a},
gW(){return new A.aB(this,this.$ti.i("aB<1>"))},
aI(a){var s,r
if(typeof a=="string"&&a!=="__proto__"){s=this.b
return s==null?!1:s[a]!=null}else if(typeof a=="number"&&(a&1073741823)===a){r=this.c
return r==null?!1:r[a]!=null}else return this.ar(a)},
ar(a){var s=this.d
if(s==null)return!1
return this.O(this.a7(s,a),a)>=0},
p(a,b){var s,r,q
if(typeof b=="string"&&b!=="__proto__"){s=this.b
r=s==null?null:A.dt(s,b)
return r}else if(typeof b=="number"&&(b&1073741823)===b){q=this.c
r=q==null?null:A.dt(q,b)
return r}else return this.aw(b)},
aw(a){var s,r,q=this.d
if(q==null)return null
s=this.a7(q,a)
r=this.O(s,a)
return r<0?null:s[r+1]},
a_(a,b,c){var s,r,q,p=this,o=p.d
if(o==null)o=p.d=A.eK()
s=A.d3(b)&1073741823
r=o[s]
if(r==null){A.du(o,s,[b,c]);++p.a
p.e=null}else{q=p.O(r,b)
if(q>=0)r[q+1]=c
else{r.push(b,c);++p.a
p.e=null}}},
af(a,b){var s,r,q,p,o,n=this,m=n.a6()
for(s=m.length,r=n.$ti.y[1],q=0;q<s;++q){p=m[q]
o=n.p(0,p)
b.$2(p,o==null?r.a(o):o)
if(m!==n.e)throw A.b(A.bG(n))}},
a6(){var s,r,q,p,o,n,m,l,k,j,i=this,h=i.e
if(h!=null)return h
h=A.ev(i.a,null,t.z)
s=i.b
r=0
if(s!=null){q=Object.getOwnPropertyNames(s)
p=q.length
for(o=0;o<p;++o){h[r]=q[o];++r}}n=i.c
if(n!=null){q=Object.getOwnPropertyNames(n)
p=q.length
for(o=0;o<p;++o){h[r]=+q[o];++r}}m=i.d
if(m!=null){q=Object.getOwnPropertyNames(m)
p=q.length
for(o=0;o<p;++o){l=m[q[o]]
k=l.length
for(j=0;j<k;j+=2){h[r]=l[j];++r}}}return i.e=h},
a7(a,b){return a[A.d3(b)&1073741823]}}
A.aC.prototype={
O(a,b){var s,r,q
if(a==null)return-1
s=a.length
for(r=0;r<s;r+=2){q=a[r]
if(q==null?b==null:q===b)return r}return-1}}
A.aB.prototype={
gj(a){return this.a.a},
gq(a){var s=this.a
return new A.bu(s,s.a6(),this.$ti.i("bu<1>"))}}
A.bu.prototype={
gm(){var s=this.d
return s==null?this.$ti.c.a(s):s},
l(){var s=this,r=s.b,q=s.c,p=s.a
if(r!==p.e)throw A.b(A.bG(p))
else if(q>=r.length){s.d=null
return!1}else{s.d=r[q]
s.c=q+1
return!0}}}
A.h.prototype={
gq(a){return new A.Z(a,this.gj(a),A.ae(a).i("Z<h.E>"))},
E(a,b){return this.p(a,b)},
F(a,b,c){return new A.B(a,b,A.ae(a).i("@<h.E>").u(c).i("B<1,2>"))},
h(a){return A.de(a,"[","]")}}
A.a_.prototype={
af(a,b){var s,r,q,p
for(s=this.gW(),s=s.gq(s),r=A.a8(this).y[1];s.l();){q=s.gm()
p=this.p(0,q)
b.$2(q,p==null?r.a(p):p)}},
gj(a){var s=this.gW()
return s.gj(s)},
h(a){return A.ew(this)}}
A.bO.prototype={
$2(a,b){var s,r=this.a
if(!r.a)this.b.a+=", "
r.a=!1
r=this.b
s=A.o(a)
s=r.a+=s
r.a=s+": "
s=A.o(b)
r.a+=s},
$S:14}
A.j.prototype={
gH(){return A.ez(this)}}
A.aW.prototype={
h(a){var s=this.a
if(s!=null)return"Assertion failed: "+A.bH(s)
return"Assertion failed"}}
A.D.prototype={}
A.y.prototype={
gN(){return"Invalid argument"+(!this.a?"(s)":"")},
gM(){return""},
h(a){var s=this,r=s.c,q=r==null?"":" ("+r+")",p=s.d,o=p==null?"":": "+p,n=s.gN()+q+o
if(!s.a)return n
return n+s.gM()+": "+A.bH(s.gV())},
gV(){return this.b}}
A.au.prototype={
gV(){return this.b},
gN(){return"RangeError"},
gM(){var s,r=this.e,q=this.f
if(r==null)s=q!=null?": Not less than or equal to "+A.o(q):""
else if(q==null)s=": Not greater than or equal to "+A.o(r)
else if(q>r)s=": Not in inclusive range "+A.o(r)+".."+A.o(q)
else s=q<r?": Valid value range is empty":": Only valid value is "+A.o(r)
return s}}
A.b0.prototype={
gV(){return this.b},
gN(){return"RangeError"},
gM(){if(this.b<0)return": index must not be negative"
var s=this.f
if(s===0)return": no indices are valid"
return": index should be less than "+s},
gj(a){return this.f}}
A.bm.prototype={
h(a){return"Unsupported operation: "+this.a}}
A.bk.prototype={
h(a){return"UnimplementedError: "+this.a}}
A.C.prototype={
h(a){return"Bad state: "+this.a}}
A.b_.prototype={
h(a){var s=this.a
if(s==null)return"Concurrent modification during iteration."
return"Concurrent modification during iteration: "+A.bH(s)+"."}}
A.av.prototype={
h(a){return"Stack Overflow"},
gH(){return null},
$ij:1}
A.c6.prototype={
h(a){return"Exception: "+this.a}}
A.c.prototype={
F(a,b,c){return A.ex(this,b,A.a8(this).i("c.E"),c)},
gj(a){var s,r=this.gq(this)
for(s=0;r.l();)++s
return s},
h(a){return A.es(this,"(",")")}}
A.p.prototype={
gn(a){return A.d.prototype.gn.call(this,0)},
h(a){return"null"}}
A.d.prototype={$id:1,
gn(a){return A.at(this)},
h(a){return"Instance of '"+A.bQ(this)+"'"},
gk(a){return A.fP(this)},
toString(){return this.h(this)}}
A.bx.prototype={
h(a){return""},
$ix:1}
A.bj.prototype={
gj(a){return this.a.length},
h(a){var s=this.a
return s.charCodeAt(0)==0?s:s}}
A.cJ.prototype={
$1(a){var s,r,q,p
if(A.dM(a))return a
s=this.a
if(s.aI(a))return s.p(0,a)
if(a instanceof A.a_){r={}
s.a_(0,a,r)
for(s=a.gW(),s=s.gq(s);s.l();){q=s.gm()
r[q]=this.$1(a.p(0,q))}return r}else if(t.x.b(a)){p=[]
s.a_(0,a,p)
B.o.aH(p,J.eg(a,this,t.z))
return p}else return a},
$S:15}
A.cB.prototype={
$1(a){var s=this.a,r=this.b.$1(this.c.a(a))
if(!s.gP())A.aS(s.I())
s.A(r)},
$S:16}
A.c0.prototype={
al(){this.a=new A.a2(null,null,null,t.I)
A.fL(self.self,"onmessage",new A.c1(this),t.m,t.P)}}
A.c1.prototype={
$1(a){var s,r=a.data,q=this.a.a
q===$&&A.e1()
s=q.b
if(s>=4)A.aS(q.ao())
if((s&1)!==0)q.A(r)
else if((s&3)===0)q.au().ad(0,new A.a5(r))},
$S:17}
A.cK.prototype={
$1(a){var s,r
if(typeof a=="string")try{s=t.m.a(self)
A.et(s,"postMessage",A.fX(a),null,null,null)}catch(r){A.h0("Received data from WASM worker but it's not a String!\n")}},
$S:4};(function aliases(){var s=J.K.prototype
s.aj=s.h
s=A.a3.prototype
s.ak=s.I})();(function installTearOffs(){var s=hunkHelpers._static_1,r=hunkHelpers._static_0,q=hunkHelpers._static_2,p=hunkHelpers._instance_2u,o=hunkHelpers._instance_0u
s(A,"fG","eF",1)
s(A,"fH","eG",1)
s(A,"fI","eH",1)
r(A,"dS","fz",0)
q(A,"fJ","fu",5)
p(A.n.prototype,"gaq","v",5)
o(A.az.prototype,"gaz","aA",0)})();(function inheritance(){var s=hunkHelpers.mixin,r=hunkHelpers.inherit,q=hunkHelpers.inheritMany
r(A.d,null)
q(A.d,[A.cP,J.b1,J.aV,A.j,A.c,A.Z,A.b6,A.ah,A.bV,A.bP,A.ag,A.aI,A.Q,A.w,A.bt,A.cr,A.cp,A.bn,A.aY,A.a1,A.T,A.a3,A.a6,A.n,A.bo,A.bv,A.bp,A.br,A.aH,A.az,A.bw,A.cu,A.a_,A.bu,A.h,A.av,A.c6,A.p,A.bx,A.bj,A.c0])
q(J.b1,[J.b2,J.aj,J.al,J.ak,J.am,J.b4,J.Y])
q(J.al,[J.K,J.t,A.b7,A.aq])
q(J.K,[J.bh,J.aw,J.J])
r(J.bN,J.t)
q(J.b4,[J.ai,J.b3])
q(A.j,[A.an,A.D,A.b5,A.bl,A.bq,A.bi,A.bs,A.aW,A.y,A.bm,A.bk,A.C,A.b_])
q(A.c,[A.e,A.R])
q(A.e,[A.L,A.aB])
r(A.af,A.R)
r(A.B,A.L)
r(A.as,A.D)
q(A.Q,[A.bE,A.bF,A.bU,A.cF,A.cH,A.c3,A.c2,A.cw,A.co,A.cb,A.ci,A.bS,A.cJ,A.cB,A.c1,A.cK])
q(A.bU,[A.bR,A.aZ])
q(A.bF,[A.cG,A.cx,A.cA,A.cc,A.bO])
q(A.aq,[A.b8,A.a0])
q(A.a0,[A.aD,A.aF])
r(A.aE,A.aD)
r(A.ao,A.aE)
r(A.aG,A.aF)
r(A.ap,A.aG)
q(A.ao,[A.b9,A.ba])
q(A.ap,[A.bb,A.bc,A.bd,A.be,A.bf,A.ar,A.bg])
r(A.aL,A.bs)
q(A.bE,[A.c4,A.c5,A.cq,A.c7,A.ce,A.cd,A.ca,A.c9,A.c8,A.ch,A.cg,A.cf,A.bT,A.cn,A.ck,A.cz,A.cm])
r(A.aJ,A.a1)
r(A.U,A.aJ)
r(A.ax,A.U)
r(A.a4,A.T)
r(A.ay,A.a4)
r(A.aK,A.a3)
r(A.a2,A.bv)
r(A.a5,A.br)
r(A.cl,A.cu)
r(A.aA,A.a_)
r(A.aC,A.aA)
q(A.y,[A.au,A.b0])
s(A.aD,A.h)
s(A.aE,A.ah)
s(A.aF,A.h)
s(A.aG,A.ah)
s(A.a2,A.bp)})()
var v={typeUniverse:{eC:new Map(),tR:{},eT:{},tPV:{},sEA:[]},mangledGlobalNames:{a:"int",l:"double",h_:"num",S:"String",fK:"bool",p:"Null",eu:"List",d:"Object",h7:"Map"},mangledNames:{},types:["~()","~(~())","p(@)","p()","~(@)","~(d,x)","@(@)","@(@,S)","@(S)","p(~())","p(@,x)","~(a,@)","p(d,x)","n<@>(@)","~(d?,d?)","d?(d?)","~(d)","p(m)"],interceptorsByTag:null,leafTags:null,arrayRti:Symbol("$ti")}
A.f_(v.typeUniverse,JSON.parse('{"bh":"K","aw":"K","J":"K","b2":{"f":[]},"aj":{"p":[],"f":[]},"al":{"m":[]},"K":{"m":[]},"t":{"e":["1"],"m":[],"c":["1"]},"bN":{"t":["1"],"e":["1"],"m":[],"c":["1"]},"b4":{"l":[]},"ai":{"l":[],"a":[],"f":[]},"b3":{"l":[],"f":[]},"Y":{"S":[],"f":[]},"an":{"j":[]},"e":{"c":["1"]},"L":{"e":["1"],"c":["1"]},"R":{"c":["2"],"c.E":"2"},"af":{"R":["1","2"],"e":["2"],"c":["2"],"c.E":"2"},"B":{"L":["2"],"e":["2"],"c":["2"],"c.E":"2","L.E":"2"},"as":{"D":[],"j":[]},"b5":{"j":[]},"bl":{"j":[]},"aI":{"x":[]},"bq":{"j":[]},"bi":{"j":[]},"b7":{"m":[],"cN":[],"f":[]},"aq":{"m":[]},"b8":{"cO":[],"m":[],"f":[]},"a0":{"u":["1"],"m":[]},"ao":{"h":["l"],"u":["l"],"e":["l"],"m":[],"c":["l"]},"ap":{"h":["a"],"u":["a"],"e":["a"],"m":[],"c":["a"]},"b9":{"bI":[],"h":["l"],"u":["l"],"e":["l"],"m":[],"c":["l"],"f":[],"h.E":"l"},"ba":{"bJ":[],"h":["l"],"u":["l"],"e":["l"],"m":[],"c":["l"],"f":[],"h.E":"l"},"bb":{"bK":[],"h":["a"],"u":["a"],"e":["a"],"m":[],"c":["a"],"f":[],"h.E":"a"},"bc":{"bL":[],"h":["a"],"u":["a"],"e":["a"],"m":[],"c":["a"],"f":[],"h.E":"a"},"bd":{"bM":[],"h":["a"],"u":["a"],"e":["a"],"m":[],"c":["a"],"f":[],"h.E":"a"},"be":{"bX":[],"h":["a"],"u":["a"],"e":["a"],"m":[],"c":["a"],"f":[],"h.E":"a"},"bf":{"bY":[],"h":["a"],"u":["a"],"e":["a"],"m":[],"c":["a"],"f":[],"h.E":"a"},"ar":{"bZ":[],"h":["a"],"u":["a"],"e":["a"],"m":[],"c":["a"],"f":[],"h.E":"a"},"bg":{"c_":[],"h":["a"],"u":["a"],"e":["a"],"m":[],"c":["a"],"f":[],"h.E":"a"},"bs":{"j":[]},"aL":{"D":[],"j":[]},"n":{"X":["1"]},"aY":{"j":[]},"ax":{"U":["1"],"a1":["1"]},"ay":{"T":["1"]},"aK":{"a3":["1"]},"a2":{"bv":["1"]},"U":{"a1":["1"]},"a4":{"T":["1"]},"aJ":{"a1":["1"]},"aA":{"a_":["1","2"]},"aC":{"aA":["1","2"],"a_":["1","2"]},"aB":{"e":["1"],"c":["1"],"c.E":"1"},"aW":{"j":[]},"D":{"j":[]},"y":{"j":[]},"au":{"j":[]},"b0":{"j":[]},"bm":{"j":[]},"bk":{"j":[]},"C":{"j":[]},"b_":{"j":[]},"av":{"j":[]},"bx":{"x":[]},"bM":{"e":["a"],"c":["a"]},"c_":{"e":["a"],"c":["a"]},"bZ":{"e":["a"],"c":["a"]},"bK":{"e":["a"],"c":["a"]},"bX":{"e":["a"],"c":["a"]},"bL":{"e":["a"],"c":["a"]},"bY":{"e":["a"],"c":["a"]},"bI":{"e":["l"],"c":["l"]},"bJ":{"e":["l"],"c":["l"]}}'))
A.eZ(v.typeUniverse,JSON.parse('{"e":1,"ah":1,"a0":1,"T":1,"ay":1,"bp":1,"a4":1,"aJ":1,"br":1,"a5":1,"aH":1,"az":1,"bw":1}'))
var u={g:"Cannot fire new event. Controller is already firing an event",c:"Error handler must accept one Object or one Object and a StackTrace as arguments, and return a value of the returned future's type"}
var t=(function rtii(){var s=A.dV
return{J:s("cN"),Y:s("cO"),V:s("e<@>"),Q:s("j"),B:s("bI"),q:s("bJ"),Z:s("h6"),O:s("bK"),k:s("bL"),U:s("bM"),x:s("c<d?>"),s:s("t<S>"),b:s("t<@>"),T:s("aj"),m:s("m"),g:s("J"),p:s("u<@>"),P:s("p"),K:s("d"),L:s("h8"),l:s("x"),N:s("S"),R:s("f"),c:s("D"),D:s("bX"),w:s("bY"),e:s("bZ"),E:s("c_"),o:s("aw"),I:s("a2<@>"),d:s("n<@>"),a:s("n<a>"),F:s("aC<d?,d?>"),y:s("fK"),i:s("l"),z:s("@"),v:s("@(d)"),C:s("@(d,x)"),S:s("a"),A:s("0&*"),_:s("d*"),W:s("X<p>?"),X:s("d?"),H:s("h_"),n:s("~"),u:s("~(d)"),f:s("~(d,x)")}})();(function constants(){B.n=J.b1.prototype
B.o=J.t.prototype
B.p=J.ai.prototype
B.q=J.Y.prototype
B.r=J.J.prototype
B.t=J.al.prototype
B.e=J.bh.prototype
B.b=J.aw.prototype
B.c=function getTagFallback(o) {
  var s = Object.prototype.toString.call(o);
  return s.substring(8, s.length - 1);
}
B.f=function() {
  var toStringFunction = Object.prototype.toString;
  function getTag(o) {
    var s = toStringFunction.call(o);
    return s.substring(8, s.length - 1);
  }
  function getUnknownTag(object, tag) {
    if (/^HTML[A-Z].*Element$/.test(tag)) {
      var name = toStringFunction.call(object);
      if (name == "[object Object]") return null;
      return "HTMLElement";
    }
  }
  function getUnknownTagGenericBrowser(object, tag) {
    if (object instanceof HTMLElement) return "HTMLElement";
    return getUnknownTag(object, tag);
  }
  function prototypeForTag(tag) {
    if (typeof window == "undefined") return null;
    if (typeof window[tag] == "undefined") return null;
    var constructor = window[tag];
    if (typeof constructor != "function") return null;
    return constructor.prototype;
  }
  function discriminator(tag) { return null; }
  var isBrowser = typeof HTMLElement == "function";
  return {
    getTag: getTag,
    getUnknownTag: isBrowser ? getUnknownTagGenericBrowser : getUnknownTag,
    prototypeForTag: prototypeForTag,
    discriminator: discriminator };
}
B.l=function(getTagFallback) {
  return function(hooks) {
    if (typeof navigator != "object") return hooks;
    var userAgent = navigator.userAgent;
    if (typeof userAgent != "string") return hooks;
    if (userAgent.indexOf("DumpRenderTree") >= 0) return hooks;
    if (userAgent.indexOf("Chrome") >= 0) {
      function confirm(p) {
        return typeof window == "object" && window[p] && window[p].name == p;
      }
      if (confirm("Window") && confirm("HTMLElement")) return hooks;
    }
    hooks.getTag = getTagFallback;
  };
}
B.h=function(hooks) {
  if (typeof dartExperimentalFixupGetTag != "function") return hooks;
  hooks.getTag = dartExperimentalFixupGetTag(hooks.getTag);
}
B.k=function(hooks) {
  if (typeof navigator != "object") return hooks;
  var userAgent = navigator.userAgent;
  if (typeof userAgent != "string") return hooks;
  if (userAgent.indexOf("Firefox") == -1) return hooks;
  var getTag = hooks.getTag;
  var quickMap = {
    "BeforeUnloadEvent": "Event",
    "DataTransfer": "Clipboard",
    "GeoGeolocation": "Geolocation",
    "Location": "!Location",
    "WorkerMessageEvent": "MessageEvent",
    "XMLDocument": "!Document"};
  function getTagFirefox(o) {
    var tag = getTag(o);
    return quickMap[tag] || tag;
  }
  hooks.getTag = getTagFirefox;
}
B.j=function(hooks) {
  if (typeof navigator != "object") return hooks;
  var userAgent = navigator.userAgent;
  if (typeof userAgent != "string") return hooks;
  if (userAgent.indexOf("Trident/") == -1) return hooks;
  var getTag = hooks.getTag;
  var quickMap = {
    "BeforeUnloadEvent": "Event",
    "DataTransfer": "Clipboard",
    "HTMLDDElement": "HTMLElement",
    "HTMLDTElement": "HTMLElement",
    "HTMLPhraseElement": "HTMLElement",
    "Position": "Geoposition"
  };
  function getTagIE(o) {
    var tag = getTag(o);
    var newTag = quickMap[tag];
    if (newTag) return newTag;
    if (tag == "Object") {
      if (window.DataView && (o instanceof window.DataView)) return "DataView";
    }
    return tag;
  }
  function prototypeForTagIE(tag) {
    var constructor = window[tag];
    if (constructor == null) return null;
    return constructor.prototype;
  }
  hooks.getTag = getTagIE;
  hooks.prototypeForTag = prototypeForTagIE;
}
B.i=function(hooks) {
  var getTag = hooks.getTag;
  var prototypeForTag = hooks.prototypeForTag;
  function getTagFixed(o) {
    var tag = getTag(o);
    if (tag == "Document") {
      if (!!o.xmlVersion) return "!Document";
      return "!HTMLDocument";
    }
    return tag;
  }
  function prototypeForTagFixed(tag) {
    if (tag == "Document") return null;
    return prototypeForTag(tag);
  }
  hooks.getTag = getTagFixed;
  hooks.prototypeForTag = prototypeForTagFixed;
}
B.d=function(hooks) { return hooks; }

B.a=new A.cl()
B.m=new A.bx()
B.u=A.A("cN")
B.v=A.A("cO")
B.w=A.A("bI")
B.x=A.A("bJ")
B.y=A.A("bK")
B.z=A.A("bL")
B.A=A.A("bM")
B.B=A.A("bX")
B.C=A.A("bY")
B.D=A.A("bZ")
B.E=A.A("c_")})();(function staticFields(){$.cj=null
$.v=A.bC([],A.dV("t<d>"))
$.dg=null
$.db=null
$.da=null
$.dX=null
$.dR=null
$.e_=null
$.cE=null
$.cI=null
$.d_=null
$.a9=null
$.aP=null
$.aQ=null
$.cW=!1
$.i=B.a})();(function lazyInitializers(){var s=hunkHelpers.lazyFinal
s($,"h5","d5",()=>A.fO("_$dart_dartClosure"))
s($,"ha","e3",()=>A.E(A.bW({
toString:function(){return"$receiver$"}})))
s($,"hb","e4",()=>A.E(A.bW({$method$:null,
toString:function(){return"$receiver$"}})))
s($,"hc","e5",()=>A.E(A.bW(null)))
s($,"hd","e6",()=>A.E(function(){var $argumentsExpr$="$arguments$"
try{null.$method$($argumentsExpr$)}catch(r){return r.message}}()))
s($,"hg","e9",()=>A.E(A.bW(void 0)))
s($,"hh","ea",()=>A.E(function(){var $argumentsExpr$="$arguments$"
try{(void 0).$method$($argumentsExpr$)}catch(r){return r.message}}()))
s($,"hf","e8",()=>A.E(A.dm(null)))
s($,"he","e7",()=>A.E(function(){try{null.$method$}catch(r){return r.message}}()))
s($,"hj","ec",()=>A.E(A.dm(void 0)))
s($,"hi","eb",()=>A.E(function(){try{(void 0).$method$}catch(r){return r.message}}()))
s($,"hk","d6",()=>A.eE())})();(function nativeSupport(){!function(){var s=function(a){var m={}
m[a]=1
return Object.keys(hunkHelpers.convertToFastObject(m))[0]}
v.getIsolateTag=function(a){return s("___dart_"+a+v.isolateTag)}
var r="___dart_isolate_tags_"
var q=Object[r]||(Object[r]=Object.create(null))
var p="_ZxYxX"
for(var o=0;;o++){var n=s(p+"_"+o+"_")
if(!(n in q)){q[n]=1
v.isolateTag=n
break}}v.dispatchPropertyName=v.getIsolateTag("dispatch_record")}()
hunkHelpers.setOrUpdateInterceptorsByTag({ArrayBuffer:A.b7,ArrayBufferView:A.aq,DataView:A.b8,Float32Array:A.b9,Float64Array:A.ba,Int16Array:A.bb,Int32Array:A.bc,Int8Array:A.bd,Uint16Array:A.be,Uint32Array:A.bf,Uint8ClampedArray:A.ar,CanvasPixelArray:A.ar,Uint8Array:A.bg})
hunkHelpers.setOrUpdateLeafTags({ArrayBuffer:true,ArrayBufferView:false,DataView:true,Float32Array:true,Float64Array:true,Int16Array:true,Int32Array:true,Int8Array:true,Uint16Array:true,Uint32Array:true,Uint8ClampedArray:true,CanvasPixelArray:true,Uint8Array:false})
A.a0.$nativeSuperclassTag="ArrayBufferView"
A.aD.$nativeSuperclassTag="ArrayBufferView"
A.aE.$nativeSuperclassTag="ArrayBufferView"
A.ao.$nativeSuperclassTag="ArrayBufferView"
A.aF.$nativeSuperclassTag="ArrayBufferView"
A.aG.$nativeSuperclassTag="ArrayBufferView"
A.ap.$nativeSuperclassTag="ArrayBufferView"})()
Function.prototype.$1=function(a){return this(a)}
Function.prototype.$0=function(){return this()}
Function.prototype.$2=function(a,b){return this(a,b)}
Function.prototype.$3=function(a,b,c){return this(a,b,c)}
Function.prototype.$4=function(a,b,c,d){return this(a,b,c,d)}
Function.prototype.$1$1=function(a){return this(a)}
convertAllToFastObject(w)
convertToFastObject($);(function(a){if(typeof document==="undefined"){a(null)
return}if(typeof document.currentScript!="undefined"){a(document.currentScript)
return}var s=document.scripts
function onLoad(b){for(var q=0;q<s.length;++q){s[q].removeEventListener("load",onLoad,false)}a(b.target)}for(var r=0;r<s.length;++r){s[r].addEventListener("load",onLoad,false)}})(function(a){v.currentScript=a
var s=A.d1
if(typeof dartMainRunner==="function"){dartMainRunner(s,[])}else{s([])}})})()
//# sourceMappingURL=worker.dart.js.map
