;; -*- coding: utf-8; lexical-binding: t -*-

EmacsLisp中的静态作用域与动态作用域

在本文中,我会演示:

Emacs Lisp中动态作用域与静态作用域之间的不同点
使用动态作用域要当心什么
静态作用域及静态闭包有什么用
当混用静态作用域和动态作用域时,会发生什么情况

Emacs Lisp 在Emacs23及以下版本中只支持动态作用域. 直到Emacs24才开始支持静态作用域的. 这很好,因为静态作用域在大多数时候都要比动态作用域更清晰易懂.本文随后会解释这一点. 若你希望使用静态作用域,需要将 -*- lexical-binding: t -*- 放到el文件的第一行中. 这样当Emacs24加载该文件时,就会对里面的代码应用静态作用域了. 举个例子,我现在Emacs初始化文件中的第一行是

;; -*- coding: utf-8 -*-
当我把这一行改成

;; -*- coding: utf-8; lexical-binding: t -*-
则Emacs初始化文件中的代码被Emacs24加载时使用的是静态作用域了. 参见 file variables.

要实验一下静态作用域,第一步创建一个空的le文件(C-x C-f lexical-scratch.el RET), 然后添加下面这行内容:

;; -*- lexical-binding: t -*-
保存一下, 然后再revert一下这个buffer(M-x revert-buffer). 现在该buffer中的代码处于静态作用域下了,你可以在该buffer中做各种尝试了.

那么,什么是动态作用域,什么又是静态作用域呢? 我们来看个简单的例子吧.

(setq a 17)
(defun my-print-a ()
  (print a))
(setq a 1717)
(let ((a 8))
  (my-print-a))

注意到在 my-print-a 中并未指定 a 变量的值,我们称呼其为“free variable”(自由变量) (也被称为 “nonlocal varibale”(非局部变量) 因为”a 不是在 my-print-a 函数内定义的”). 上面代码的运行结果会是什么呢?会输出1717呢还是8? 在动态作用域下,它输出8,但在静态作用域下,输出为1717. 在动态作用域下, my-print-a 中 a 所引用的值由 my-print-a 的调用环境所决定. 而在静态作用域下, a 的值由 my-print-a 的定义环境所决定.

在动态作用域下,该代码输出8是因为,调用 my-print-a 的时机,是在一个let语句中,在let语句内, a 的值被绑定到8. 若你是在let语句外面调用 my-print-a 则会输出1717.

在静态作用域下,代码输出1717是因为,首先, my-print-a 是在let语句外定义的,因此 my-print-a 中的 a 所引用的是 a 的全局绑定,而不是由let语句所创建的局部绑定(所谓绑定是指将名字 a 绑定到或分配给一块内存地址). 其次,当 my-print-a 调用时, a 的全局的值变成了1717,它是与8这个局部值是相隔离的. 若你将 my-print-a 的定义移到let语句中,则输出的值会是8,这是因为这时 my-print-a 中的 a 引用的是let语句所创建的局部绑定.

如果你会JavaScript, 那么上面那段代码其实相当于下面这段JavaScript代码

var a;
a = 17;
function myPrintA() {
    console.log(a);
}
a = 1717;
(function () {
    var a = 8;
    myPrintA();
}());
这段JavaScript代码会输出 1717. 现在大多数的编程语言都是使用静态作用域的.

若你使用的是Emacs24, 你可以在scratch buffer中运行以下代码,来看看在静态作用域下,我上面的例子是否真的输出1717.

(eval
 '(progn
    (setq a 17)
    (defun my-print-a ()
      (print a))
    (setq a 1717)
    (let ((a 8))
      (my-print-a)))
 t)

Emacs24的 eval 函数可以接受第二个可选参数, 若该参数的值为t则表示在静态作用域下执行代码. 执行时,可别忘了 =(progn …)前的’哦.

支持静态作用域是创建静态闭包的基础. 那么什么是静态闭包呢? 让我们看看下面这段代码:

(setq a 0)
(let ((a 17))
  (defun my-print-a ()
    (print a))
  (setq a 1717))
(let ((a 8))
  (my-print-a))
在静态作用域下,其输出为1717. 下面是Alice针对上面代码的解释:

咋一看,得出这个结果并不奇怪,但是若你仔细观察,就会发现有点奇怪了. 一开始,我想”这是静态作用域下,因此 my-print-a 中的 a 引用的是第一个let语句中创建的额局部绑定. 所以输出1717是理所当然的事情了” 但我再一看,发现 my-print-a 调用时,其中 a 所引用的由第一个let语句创建的局部绑定不是应该已经过期了吗? 你怎么可能还能使用过期的变量呢! 为什么会输出1717而不是提示”对不起,我已经不存在了”呢? 这里明明应该报错,为什么却没有呢?
第一个局部绑定通过某种方式在第一个let语句退出后还依然存在,并且只允许 my-print-a 来访问它. 这意味着Emacs肯定在低层维护着这些变量,这才使得静态作用域工作的要比想像中的更好.

那么,什么是静态闭包呢? 这与静态作用域的实现原理相关. my-print-a 的function cell 中包含了一个指向 a 的那个本应过期的绑定, 你可以通过执行
(symbol-function 'my-print-a)
来看到这一点. 这种结合函数定义以及指向函数创建时作用域的指针的组合物就叫做静态闭包. 你也可以称呼任何能访问已过期绑定的静态作用域函数为静态闭包. 静态闭包也简称闭包. 但并不是所有的静态作用域语言都支持闭包.

在静态作用域下,当你想看看函数体中某个变量引用的是什么东西时,你只需要看看函数体是在代码的哪个地方定义的,然后找到相关绑定即可. 这也是为什么静态作用域写的代码更清晰的原因,我们所要做的仅仅是看一下变量是在哪个位置定义就行了,也无需担心相关的绑定会过期.

总之,上面代码的用JavaScript表示就是:

var a, myPrintA;
a = 0;
(function () {
    // local variable a
    var a = 17;
    myPrintA = function () {
        console.log(a);
    };
    a = 1717;
}());
(function () {
    // local variable a
    var a = 8;
    myPrintA();
}());
其输出结果为1717,因为JavaScript支持静态作用域.

在Emacs 24内部, 静态作用域函数是由格式为 (closure ENV ARGS BODY...) 的form来表示的, 而动态作用域函数是由格式为 (lambda ARGS BODY...) 的form来表示的(其格式与你在Emacs Lisp中书写的匿名函数是一样的). 下面这段代码在动态作用域下会输出 (lambda (x y) (+ x y)) 两次,在静态作用域下会输出 (closure (t) (x y) (+ x y)) 两次

(defun my-sum (x y) (+ x y))
;; print the contents of function cell of my-sum
(print (symbol-function 'my-sum))
;; print an anonymous function
(print (lambda (x y) (+ x y)))
貌似 (lambda ...) 语句的执行结果在动态作用域下就是它自己,而在静态作用域下则是 (closure ...).

下面聊聊嵌套定义的情况. 在静态作用域下,若A函数定义了B函数(即是说B函数是在A函数的函数体中定义的),B函数又定义了C函数,那么当C函数输出 a 时,先会在函数C中查找 a 的引用,若没有找到,则会去函数B(函数C定义的位置)中查找 a 的引用,以此类推.

在动态作用域下,假设我们有一个函数 my-func1,这个函数调用了函数 my-func2, my-func2 函数又调用了 my-func3,函数 my-func3 输出 a 的值. my-func2 在调用 my-func3 时在本地设置 a 为2. 那么在在动态作用域下调用 my-func1 会有什么结果呢? 它会输出 2. 那么,若我是在一个将 a 设为1的环境调用 my-func1,又会是什么结果呢? 它还是输出2而不是1. 可以使用以下代码进行测试:

(defun my-func1 ()
  (my-func2))
(defun my-func2 ()
  (let ((a 2))
    (my-func3)))
(defun my-func3 ()
  (print a))
(let ((a 1))
  (my-func1))
其执行过程是这样的,在将 a 局部绑定为1的情况下调用 my-func1 ,然后 my-func1 又调用 my-func2. 接下来, my-func2 为a又创建了一个局部绑定,从而屏蔽了之前那个将 a 绑定为1的局部绑定了. 这个执行时点,就好像是 (let ((a 1)) (let ((a 2)) X )) 中的X一样,在这个时点调用 my-func3 当然会输出2了.

动态作用域有一个弊端你应该知道的. 假设你你想调用一个以函数为参数的函数.

(defun my-call (f n)
  (funcall f n))

(my-call #'1+ 5) ; => 6
(my-call #'oddp 5) ; => t

(dolist (i (list 1 2 3))
  (print
   (my-call (lambda (x) (* i x)) 5))) ; 输出 5 10 15
目前看来没什么问题. 接下来我们试试

(dolist (n (list 1 2 3))
  (print
   (my-call (lambda (x) (* n x)) 5))) ; 动态作用域下会输出 25 25 25
怎么会这样? 问题的关键在于 (lambda (x) (* n x)) 中的 n 与 my-call 中的参数同名了. 匿名函数 (lambda (x) (* n x)) 是在 my-call 中被调用的,而 my-call 函数内,参数 n 被绑定成了5了. 在静态作用域中上面代码会如愿输出 5 10 15

缺陷 1 – 将一个动态作用域下的函数作为参数传递給另一个函数可能会有问题! (Update: 所谓动态作用域下的函数是指在动态作用域文件中定义的函数. 所以与其从函数的角度来思考这个问题不如从动态作用域文件对比静态作用域文件的角度来思考这个问题. 或者更精确一点, 是动态作用域elisp buffer中的动态作用域代码 vs 静态作用域elisp buffer中的静态作用域代码 请参见 http://stackoverflow.com/questions/7654848/what-are-the-new-rules-for-variable-scoping-in-emacs-24 )

让我们来看另一个问题. 尝试定义一个函数,其接受两个函数f和g,并返回一个组合函数等价于先调用g函数然后再用结果调用f函数.

;; in dynamic scoping
(defun my-compose (f g)
  (lambda (x)
    (funcall f (funcall g x))))

(funcall
 (my-compose (lambda (n) (+ n 3)) (lambda (n) (+ n 20)))
 100) ; 结果报错, Lisp error: (void-variable f)
错误信息告诉我们 f 没有定义. 为什么会这样? 因为组合函数是在 my-compose 中创建的, 但是在另一个 f 和 g 都没有绑定的地方调用的. 当然,如果是静态作用域,则上面代码运行结果与预期一样.

缺陷 2 – 使用从动态作用域函数返回的函数可能会有问题!

在Emacs 24中, defvar 创建的变量称为 special variables. Special variables 是动态作用域变量,即使它在静态作用域函数中创建的绑定也是动态绑定. case-fold-search 就是个special variable的例子. 函数 search-forward 是否大小写敏感依赖于 case-fold-search 的值. 当 case-fold-search 设为t时, (search-forward "hello") 能够匹配”HELLO”, 当 case-fold-search 为 nil时则不匹配. 假设你在静态作用域下的el文件中定义自己的 my-search-forward 函数,且在 my-search-forward 中也使用 case-fold-search 来决定是否大小写敏感. 由于 case-fold-search 为special variable, 因此当你调用

(let ((case-fold-search t))
  (my-search-forward "hello"))
你可以确定该搜索是大小写不敏感的.

你可以使用函数 special-variable-p 来判断一个变量是否special.

(special-variable-p 'print-level) ; => t
(special-variable-p 'print-length) ; => t
(special-variable-p 'debug-on-error) ; => t
(special-variable-p 'debug-on-quit) ; => t
Special variables某些情况下很有用. gsg在reddit中曾经说过:

动态作用域允许你給参数化代码而无需明确地传递一个参数. 把这种方式作为默认的行为不太好,但是有些代码确实能因此而收益.
kragensitaker也说过:

有些情况下需要使用动态作用域,例如Thread-local变量, 异常处理器, 当前语言环境, 当前选中的区域 以及图形转换等.
接下来让我们看看静态作用域有什么用.

在静态作用域下运行下面代码.

(let (c)
  (defun my-get-c ()
    c)
  (defun my-set-c (new-c)
    (setq c new-c))
  (defun my-add-to-c (x)
    (setq c (+ x c))))
然后在下面的代码中使用这三个函数. 由于在动态作用域下调用的静态函数依然是静态函数(Update:也许这样解释比较好:函数调用仅仅只是调用函数而已,它仅仅执行函数体的代码,二不会改变函数体的代码. 函数体依然处于静态作用域环境下. 因此,函数体中的变量(special varialbe除外)依然是引用的静态绑定),因此不管你是否在静态作用域下运行,其结果都是一样的.

(my-set-c 10)
(my-add-to-c 5)
(print (my-get-c)) ; prints 15.
(my-add-to-c 1)
(print (my-get-c)) ; prints 16
(let ((c 0))
  (print c) ; prints 0
  (print (my-get-c))) ; prints 16.
my-get-c, my-set-c, 和 my-add-to-c 共享同一个 c 绑定,这使得 c 就好像是一个私有变量一样, 并且与其他名为 c 的绑定(例如 (let ((c 0)) ...) 中的c)相独立. 之所以会这样是因为创建这个c绑定的let语句包含了这三个 defun 语句,因此除了这三个函数能访问以外,对于其他的访问来说 c 以及过期了.

Now let’s test using lexical closures to do what static variables in C do.

(require 'cl) ; for incf
(eval
 '(let ((i 0))
    (defun my-counter ()
      (prog1
          i
        (incf i))))
 t)
(my-counter) ; => 0
(my-counter) ; => 1
(my-counter) ; => 2
(let ((i 10))
  (my-counter)) ; => 3
(my-counter) ; => 4
若你觉得很奇怪,为什么上面代码的输出是这样的,请看下面的演示案例.

(eval
 '(let ((i1 0))
    (defun my-test ()
      (let ((i2 0))
        (prog1
            (list i1 i2)
          (incf i1)
          (incf i2)))))
 t)
(my-test) ; => (0 0)
(my-test) ; => (1 0)
(my-test) ; => (2 0)
我们定义了 my-test 函数,然后调用这个函数三次. my-test 中的let语句 (let ((i2 0)) ..) 也随之执行了三次. 另一方面,let语句 (let ((i1 0)) ... ) 仅仅在定义 my-test 时执行了一边. 我希望这个例子能有助于你的理解.

下面让我们测试一个返回闭包函数的函数.

(eval
 '(defun my-get-counter (start step)
    (let ((count start))
      (lambda ()
        (prog1
            count
          (setq count (+ count step)))))
    )
 t)

(setq my-get-even-numbers (my-get-counter 0 2)
      my-get-odd-numbers (my-get-counter 1 2))

(funcall my-get-even-numbers) ; => 0
(funcall my-get-even-numbers) ; => 2
(funcall my-get-even-numbers) ; => 4

(funcall my-get-odd-numbers) ; => 1
(funcall my-get-odd-numbers) ; => 3
(funcall my-get-odd-numbers) ; => 5

(funcall my-get-even-numbers) ; => 6
(funcall my-get-even-numbers) ; => 8

(setq my-get-even-numbers-2 (my-get-counter 0 2))
(funcall my-get-even-numbers-2) ; => 0
(funcall my-get-even-numbers-2) ; => 2
(funcall my-get-even-numbers-2) ; => 4

(funcall my-get-even-numbers) ; => 10
(funcall my-get-even-numbers) ; => 12
(funcall my-get-even-numbers) ; => 14
你可能会觉得奇怪,为什么 my-get-even-numbers, my-get-odd-numbers 以及 my-get-even-numbers-2 看起来有自己独立的 count 变量一样,而不是共享同一个 count 变量呢? 答案是,它们确实有自己独立的 count 变量. 若你感到困惑不解, 你可以试试在静态作用域下执行以下代码,看结果是什么.

(let ((count 0))
  (setq my-count
        (lambda ()
          (prog1
              count
            (setq count (1+ count))))))
(let ((count 0))
  (setq my-count-2
        (lambda ()
          (prog1
              count
            (setq count (1+ count))))))
my-count 与 my-count-2 都有它们自己独立的 count 变量. 这两个let语句各自包含了各自的 (setq .. (lambda ...)) 语句. 这与 my-get-counter 是一样的请看. 每次执行 (my-get-counter ..) 都会执行一次 (let ((count ..)) (lambda ..)), 每次都会为 count 创建一个新的独立的绑定給新返回的函数访问. 当你调用 (my-get-counter ..) 三次, (let ((count ..)) (lambda ..)) 也被执行了三次, 创建了三个 count 绑定和三个返回的函数.

Alice现在写的所有Emacs Lisp代码都使用静态作用域. 那么当混用静态作用域代码和动态作用域代码时,会有什么后果呢?

让我们从一个简单的例子开始.

(eval
 '(defun my-bah ())
 t)

(eval
 '(fset 'my-bah-2 (symbol-function 'my-bah))
 nil)
函数 my-bah 是定义在静态作用域环境的. 因此它肯定是静态作用域函数. 那么 my-bah-2 呢? Alice认为”函数 my-bah-2 是在动态作用域环境下定义的,因此它肯定是动态作用域函数”. 但是另一方面,Bob认为”my-bah-2 中function-cell的内容就是拷贝的 my-bah 中function cell的内容. 及润 my-bah 中function-cell的内容是静态作用域函数,那么 my-bah-2 中function cell的内容也应该是静态作用域函数”. Alice说”目前这些函数啥都不干,让我们修改一下它们,让它们通过返回值告诉我们它们是否处于静态作用域下”

下面这段代码在静态作用域下会返回t,否则返回nil. Checking the value of lexical-binding instead here is a bad idea.

(let ((x nil)
      (f (let ((x t)) (lambda () x))))
  (funcall f))
Alice 修改了一下 my-bah 以及 my-bah-2 的代码.

(eval
 '(defun my-bah ()
    (let ((x nil)
          (f (let ((x t)) (lambda () x))))
      (funcall f)))
 t)

(eval
 '(fset 'my-bah-2 (symbol-function 'my-bah))
 nil)
让我们看看 my-bah-2 是否是静态作用域函数.

(my-bah) ; => t
(my-bah-2) ; => t
看起来Bob是对的. 让我们不用 defun 再试一次.

(eval
 '(setq my-nah
        (lambda ()
          (let ((x nil)
                (f (let ((x t)) (lambda () x))))
            (funcall f))))
 t)

(eval
 '(setq my-nah-2 my-nah)
 nil)

(funcall my-nah) ; => t
(funcall my-nah-2) ; => t
当你运行 (setq abc (+ 1 1)) 时,会先计算 (+ 1 1) 表达式得到2,然后将计算结果,数字2,赋给变量 abc. 类似的,当你运行 (setq my-nah (lambda ...)), 会先执行 (lambda ...),其结果是一个匿名函数. 在静态作用域下,执行结构是一个类似 (closure ....) 的静态作用域函数. 然后这个静态作用域表达式被赋予变量 my-nah.

先运行 (setq abc (+ 1 1)) 随后再运行 (setq abc-2 abc) 的执行过程中, 表达式 (+ 1 1) 只会执行一次. 语句 (setq abc-2 abc) 并不会再一次执行 (+ 1 1) , 它仅仅是将以及计算出的结果2保存到 abc-2 中. 真正执行的其实是符号 abc 自己,而符号 abc 的执行结果就是2. 类似的,在上面 my-nah 及 my-nah-2 的例子中, (lambda ...) 只会执行一次, 其结果是 (closure ...) .在你运行 (setq my-nah-2 my-nah) 时并不会再次执行代码重新生成一个结果, 而仅仅是以及计算出的结果保存到 my-nah-2 中. 虽然说 (setq my-nah-2 my-nah) 是在动态作用域环境下运行的,然而由于匿名函数表达式是在静态作用域环境中运行的, 变量 my-nah-2 最终持有的是静态作用域函数.

一个静态作用域函数创建出来后,即使是在动态作用域环境中被赋值給其他变量,其依然还是静态作用域函数.

上面 defun my-bah 的例子也类似. 符号 my-bah 的function cell中持有的是一个静态作用域函数,然后这个静态作用域函数被赋值给了别人. 你可以试试下面代码的结果.

(print my-nah-2)
(print (symbol-function 'my-bah-2))
因此,当你在静态作用域文件中用 defun 定义了函数. 要想知道该函数中的自由变量引用的是什么,只需要在源文件中查找就行了,无需担心该函数会在静态作用域文件中收同名变量的影响.

理解了 my-nah-2 & my-bah-2 的那个例子后,让我们再来看看 my-get-counter. 既然 (defun my-get-counter ...) 是在静态作用域源文件中,那么 my-get-counter are 返回的函数也应该静态作用域的. 让我们来看下面这段代码.

(eval
 '(progn
    (setq my-get-even-numbers (my-get-counter 0 2))
    (print (funcall my-get-even-numbers))
    (print (funcall my-get-even-numbers))
    (print (funcall my-get-even-numbers)))
 nil)
其结果输出 0 2 4. Alice的观点是这样的:”函数 my-get-even-numbers 是在动态作用域环境中定义的. 但是为什么它运行起来就好像是静态作用域函数一样呢?”. 其实,与 my-nah-2 一样, my-get-even-numbers 变量持有的也是静态作用域函数. 为防你感到迷惑,让我们先来看看 my-get-sum 函数.

(defun my-get-sum (x y)
  (+ x y))
my-get-sum 中的 (+ x y) 是一个加法表达式.而 my-get-sum 返回的是计算 (+ x y) 的结果,而不是 (+ x y) 本身. 当你运行 (my-get-sum 1 2) 时,其返回的并不是字面表达式 (+ x y),而是 my-get-sum 内 (+ x y) 的计算结果 3.

回到 my-get-counter. my-get-counter 中的 (lambda ...) 是一个匿名函数表达式. 该表达式在 my-get-counter 内执行一次,其结果(类似 (closure ...) 的东西)被立即返回并存储在变量 my-get-even-numbers 中. (lambda ...) 仅仅被执行一次,且执行环境是静态作用域函数 my-get-counter 的内部. 在静态作用域函数内执行lambda语句,其结果总是 (closure ...). 这就是为什么 my-get-even-numbers 最终持有的是静态作用域函数的缘故了.

另外,静态作用域函数也能创建并返回一个动态作用域函数, 只要以某种方式绕过执行lambda语句就行.

(eval
 '(defun my-return-dynamically-scoped-function ()
    (list 'lambda '() 'a)
    )
 t)

(eval
 '(defun my-return-dynamically-scoped-function ()
    '(lambda () a) ; quoted lambda
    )
 t)
我不知道这么做的理由,但是确实可以这么做.

现在让我们再来看看 my-call 的例子.

(eval
 '(defun my-call (f n)
    (funcall f n))
 nil)

(eval
 '(dolist (n (list 1 2 3))
    (print
     (my-call (lambda (x) (* n x)) 5)))
 t)
其输出为 5 10 15. Alice可能又要说了:”函数 f 是在动态作用域环境中定义的,为什么它运行起来就好像静态作用域函数一样?” 传递給 my-call 的匿名函数是在静态作用域环境中定义的, 因此它被传递給 my-call 后依然是静态作用域函数. 若你还不明白,你可以这么想, (lambda ...) 的执行结果被传递给了 my-call. my-call 经该执行结果存储在了它的局部变量 f 中. 因此,最终 f 引用的是静态作用域函数.

函数 mapcar* 与 my-call 类似,都接受一个函数作为参数,而且目前来看,其本身也是定义在动态作用域源文件中的(译者注:现在已经修复了这个问题). 下面这个动态作用域陷阱来源于 StackOverflow .

(let ((cl-x 10))
  (mapcar* (lambda (elt) (* cl-x elt)) '(1 2 3)))
mapcar* 的定义中也使用了 cl-x 作为参数名称. 因此在动态作用域中执行上面代码会有奇怪的结果(缺陷1). 但若你在静态作用域中运行该代码则没有问题,这是因为静态作用域匿名函数传递到 mapcar* 中依然是静态作用域函数.

就上面这些例子来看,似乎静态作用域要更好一些. 是时候拥抱静态作用域了.

(更新: 还可以看看Invasion of special variables 它展示了其他一些陷阱以及如何避免的方法)
