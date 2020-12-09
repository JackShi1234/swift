//
//  GCDAndOperationQueue.swift
//  swiftStudy
//
//  Created by 张小二 on 2020/12/9.
//

import Foundation
import UIKit

/* 串行队列（Serial Queues）
   串行队列适合管理共享资源。保证了顺序访问，杜绝了资源竞争。
   由 log 可知: GCD 切到主线程也需要时间，切换完成之前，指令可能已经执行到下个循环了。但是看起来图片还是依次下载完成和显示的，因为每一张图切到主线程显示都需要时间。
 
private func serialExcuteByGCD(){
    let lArr : [UIImageView] = [imageView1, imageView2, imageView3, imageView4]

    //串行队列，异步执行时，只开一个子线程
    let serialQ = DispatchQueue.init(label: "com.companyName.serial.downImage")

    for i in 0..<lArr.count{
        let lImgV = lArr[i]

        //清空旧图片
        lImgV.image = nil

     //注意，防坑：串行队列创建的位置,在这创建时，每个循环都是一个新的串行队列，里面只装一个任务，多个串行队列，整体上是并行的效果。
        //            let serialQ = DispatchQueue.init(label: "com.companyName.serial.downImage")

        serialQ.async {

            print("第\(i)个 开始，%@",Thread.current)
            Downloader.downloadImageWithURLStr(urlStr: imageURLs[i]) { (img) in
                let lImgV = lArr[i]

                print("第\(i)个 结束")
                DispatchQueue.main.async {
                    print("第\(i)个 切到主线程更新图片")
                    lImgV.image = img
                }
                if nil == img{
                    print("第\(i+1)个img is nil")
                }
            }
        }
    }
}*/

/* 并发队列（Concurrent Queues）
   对比：barrier 和锁的区别

   依赖对象不同，barrier 依赖的对象是自定义并发队列，锁操作依赖的对象是线程。
   作用不同，barrier 起到自定义并发队列中栅栏的作用；锁起到多线程操作时防止资源竞争的作用。
 
 
 private func concurrentExcuteByGCD(){
         let lArr : [UIImageView] = [imageView1, imageView2, imageView3, imageView4]

         for i in 0..<lArr.count{
             let lImgV = lArr[i]

             //清空旧图片
             lImgV.image = nil

             //并行队列:图片下载任务按顺序开始，但是是并行执行，不会相互等待，任务结束和图片显示顺序是无序的，多个子线程同时执行，性能更佳。
             let lConQ = DispatchQueue.init(label: "cusQueue", qos: .background, attributes: .concurrent)
             lConQ.async {
                 print("第\(i)个开始，%@", Thread.current)
                 Downloader.downloadImageWithURLStr(urlStr: imageURLs[i]) { (img) in
                     let lImgV = lArr[i]
                       print("第\(i)个结束")
                     DispatchQueue.main.async {
                         lImgV.image = img
                     }
                     if nil == img{
                         print("第\(i+1)个img is nil")
                     }
                 }
             }
         }
     }
 */

/*
 
 无论串行还是并发队列，都是 FIFO ； 一般创建 任务（blocks）和加任务到队列是在主线程，但是任务执行一般是在其他线程（asyc）。需要刷新 UI 时，如果当前不再主线程，需要切回主线程执行。当不确定当前线程是否在主线程时，可以使用下面代码：
 /**
 Submits a block for asynchronous execution on a main queue and returns immediately.
 */
 static inline void dispatch_async_on_main_queue(void (^block)()) {
 if (NSThread.isMainThread) {
     block();
 } else {
     dispatch_async(dispatch_get_main_queue(), block);
 }
 }
 
 主队列是串行队列，每个时间点只能有一个任务执行，因此如果耗时操作放到主队列，会导致界面卡顿。
 系统提供一个串行主队列，4个 不同优先级的全局队列。 用 dispatch_get_global_queue 方法获取全局队列时，第一个参数有 4 种类型可选:

 DISPATCH_QUEUE_PRIORITY_HIGH
 DISPATCH_QUEUE_PRIORITY_DEFAULT
 DISPATCH_QUEUE_PRIORITY_LOW
 DISPATCH_QUEUE_PRIORITY_BACKGROUND
 串行队列异步执行时，切到主线程刷 UI 也需要时间，切换完成之前，指令可能已经执行到下个循环了。但是看起来图片还是依次下载完成和显示的，因为每一张图切到主线程显示都需要时间。详见 demo 示例。
 iOS8 之后，如果需要添加可被取消的任务，可以使用 DispatchWorkItem 类，此类有 cancel 方法。
 应该避免创建大量的串行队列,如果希望并发执行大量任务，请将它们提交给全局并发队列之一。创建串行队列时，请尝试为每个队列确定一个用途，例如保护资源或同步应用程序的某些关键行为(如蓝牙检测结果需要有序处理的逻辑)。
 
*/

/*
 
 dispatch_after

      dispatch_after 函数并不是在指定时间之后才开始执行处理，而是在指定时间之后将任务追加到队列中。这个时间并不是绝对准确的。   代码示例:
 dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
         NSLog(@"2s后执行");
     });
*/

/*
 
 dispatch_semaphore

       在多线程访问可变变量时，是非线程安全的。可能导致程序崩溃。此时，可以通过使用信号量（semaphore）技术，保证多线程处理某段代码时，后面线程等待前面线程执行，保证了多线程的安全性。使用方法记两个就行了，一个是wait（dispatch_semaphore_wait），一个是signal（dispatch_semaphore_signal）
*/

/*
 
 dispatch_apply

      当每次迭代中执行工作与其他所有迭代中执行的工作不同，且每个循环完成的顺序不重要时，可以用 dispatch_apply 函数替换循环。注意：替换后， dispatch_apply 函数整体上是同步执行，内部 block 的执行类型（串行/并发）由队列类型决定，但是串行队列易死锁，建议用并发队列。
 原循环：
 for (i = 0; i < count; i++) {
    printf("%u\n",i);
 }
 printf("done");
 优化后：
 dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

  //count 是迭代的总次数。
 dispatch_apply(count, queue, ^(size_t i) {
    printf("%u\n",i);
 });

 //同样在上面循环结束后才调用。
 printf("done");
 */

/*
 
 自问自答

 一个队列的不同任务可以在多个线程执行吗？ 答：串行队列，异步执行时，只开一个子线程；无所谓多个线程执行； 并发队列，异步执行时，会自动开多个线程，可以在多个线程并发执行不同的任务。

 一个线程可以同时执行多个队列的任务吗？ 答：一个线程某个时间点只能执行一个任务，执行完毕后，可能执行到来自其他队列的任务（如果有的话）。比如：主线程除了执行主队列中任务外，也可能会执行非主队列中的任务。

 队列与线程关系示例图： queues & threads
 qualityOfService 和 queuePriority 的区别是什么？ 答： qualityOfService:      用于表示 operation 在获取系统资源时的优先级，默认值：NSQualityOfServiceBackground，我们可以根据需要给 operation 赋不同的优化级，如最高优化级：NSQualityOfServiceUserInteractive。 queuePriority:      用于设置 operation 在 operationQueue 中的相对优化级，同一 queue 中优化级高的 operation(isReady 为 YES) 会被优先执行。      需要注意区分 qualityOfService (在系统层面，operation 与其他线程获取资源的优先级) 与 queuePriority (同一 queue 中 operation 间执行的优化级)的区别。同时，需要注意 dependencies (严格控制执行顺序)与 queuePriority (queue 内部相对优先级)的区别。

 添加依赖后，队列中网络请求任务有依赖关系时，任务结束判定以数据返回为准还是以发起请求为准？ 答：以发起请求为准。
 */

/*
 
 OperationQueue

 NSOperation      NSOperation 是一个"抽象类"，不能直接使用。抽象类的用处是定义子类共有的属性和方法。NSOperation 是基于 GCD 做的面向对象的封装。相比较 GCD 使用更加简单，并且提供了一些用 GCD 不是很好实现的功能。是苹果公司推荐使用的并发技术。它有两个子类：

 NSInvocationOperation (调用操作)
 NSBlockOperation (块操作)      一般常用NSBlockOperation，代码简单，同时由于闭包性使它没有传参问题。任务被封装在 NSOperation 的子类实例类对象里，一个 NSOperation 子类对象可以添加多个任务 block 和 一个执行完成 block ，当其关联的所有 block 执行完时，就认为操作结束了。
 NSOperationQueue       OperationQueue也是对 GCD 的高级封装，更加面向对象，可以实现 GCD 不方便实现的一些效果。被添加到队列的操作默认是异步执行的。

 PS：常见的抽象类有：

 UIGestureRecognizer
 CAAnimation
 CAPropertyAnimation
 可以实现 非FIFO 效果

 通过对不同操作设置依赖,或优先级，可实现 非FIFO 效果。   代码示例:
 func testDepedence(){
         let op0 = BlockOperation.init {
             print("op0")
         }

         let op1 = BlockOperation.init {
             print("op1")
         }

         let op2 = BlockOperation.init {
             print("op2")
         }

         let op3 = BlockOperation.init {
             print("op3")
         }

         let op4 = BlockOperation.init {
             print("op4")
         }

         op0.addDependency(op1)
         op1.addDependency(op2)

         op0.queuePriority = .veryHigh
         op1.queuePriority = .normal
         op2.queuePriority = .veryLow

         op3.queuePriority = .low
         op4.queuePriority = .veryHigh

         gOpeQueue.addOperations([op0, op1, op2, op3, op4], waitUntilFinished: false)
     }
 执行结果
 op4
 op2
 op3
 op1
 op0
 
 
 说明：操作间不存在依赖时，按优先级执行；存在依赖时，按依赖关系先后执行（与无依赖关系的其他任务相比，依赖集合的执行顺序不确定）
 */

/*
 
 队列暂停/继续

 通过对队列的isSuspended属性赋值，可实现队列中未执行任务的暂停和继续效果。正在执行的任务不受影响。
 ///暂停队列，只对未执行中的任务有效。本例中对串行队列的效果明显。并发队列因4个任务一开始就很容易一起开始执行，即使挂起也无法影响已处于执行状态的任务。
     @IBAction func pauseQueueItemDC(_ sender: Any) {
         gOpeQueue.isSuspended = true
     }

     ///恢复队列，之前未开始执行的任务会开始执行
     @IBAction func resumeQueueItemDC(_ sender: Any) {
        gOpeQueue.isSuspended = false
     }
 */

/*
 
 取消操作

 一旦添加到操作队列中，操作对象实际上归队列所有，不能删除。取消操作的唯一方法是取消它。可以通过调用单个操作对象的 cancel 方法来取消单个操作对象，也可以通过调用队列对象的 cancelAllOperations 方法来取消队列中的所有操作对象。
 更常见的做法是取消所有队列操作，以响应某些重要事件，如应用程序退出或用户专门请求取消，而不是有选择地取消操作。
 取消单个操作对象
 取消（cancel）时，有 3 种情况： 1.操作在队列中等待执行，这种情况下，操作将不会被执行。 2.操作已经在执行中，此时，系统不会强制停止这个操作，但是，其 cancelled属性会被置为 true 。 3.操作已完成，此时，cancel 无任何影响。

 取消队列中的所有操作对象
 方法： cancelAllOperations。同样只会对未执行的任务有效。 demo 中代码：
 deinit {
     gOpeQueue.cancelAllOperations()
     print("die:%@",self)
 }
 */

/*
 
 通过设置操作间依赖，可以实现 非FIFO 的指定顺序效果。那么，通过设置最大并发数为 1 ，可以实现指定顺序效果吗？ A:不可以！ 设置最大并发数为 1 后，虽然每个时间点只执行一个操作，但是操作的执行顺序仍然基于其他因素，如操作的依赖关系，操作的优先级（依赖关系比优先级级别更高，即先根据依赖关系排序;不存在依赖关系时，才根据优先级排序）。因此，序列化 操作队列 不会提供与 GCD 中的序列 分派队列 完全相同的行为。如果操作对象的执行顺序对您很重要，那么您应该在将操作添加到队列之前使用 依赖关系 建立该顺序，或改用 GCD 的 串行队列 实现序列化效果。

 Operation Queue的 block 中为何无需使用 [weak self] 或 [unowned self] ？ A:即使队列对象是为全局的，self -> queue -> operation block -> self，的确会造成循环引用。但是在队列里的操作执行完毕时，队列会自动释放操作，自动解除循环引用。所以不必使用 [weak self] 或 [unowned self] 。 此外，这种循环引用在某些情况下非常有用，你无需额外持有任何对象就可以让操作自动完成它的任务。比如下载页面下载过程中，退出有循环引用的界面时，如果不执行 cancelAllOperation 方法，可以实现继续执行剩余队列中下载任务的效果。
 
 */

/*
 
 操作的 QOS 和队列的 QOS 有何关系？ A:队列的 QOS 设置，会自动把较低优先级的操作提升到与队列相同优先级。（原更高优先级操作的优先级保持不变）。后续添加进队列的操作，优先级低于队列优先级时，也会被自动提升到与队列相同的优先级。 注意，苹果文档如下的解释是错误的 This property specifies the service level applied to operation objects added to the queue. If the operation object has an explicit service level set, that value is used instead.
 
 */

/*
 
 资源竞争可能导致数据异常，死锁，甚至因访问野指针而崩溃。

 对于有明显先后依赖关系的任务，最佳方案是 GCD串行队列,可以在不使用线程锁时保证资源互斥。
 其他情况，对存在资源竞争的代码加锁或使用信号量（初始参数填1，表示只允许一条线程访问资源）。
 串行队列同步执行时，如果有任务相互等待，会死锁。 比如：在主线程上同步执行任务时，因任务和之前已加入主队列但未执行的任务会相互等待，导致死锁。
 func testDeadLock(){
     //主队列同步执行，会导致死锁。block需要等待testDeadLock执行，而主队列同步调用，又使其他任务必须等待此block执行。于是形成了相互等待，就死锁了。
     DispatchQueue.main.sync {
         print("main block")
     }
     print("2")
 }
 
 
 但是下面代码不会死锁，故串行队列同步执行任务不一定死锁。
 - (void)testSynSerialQueue{
     dispatch_queue_t myCustomQueue;
     myCustomQueue = dispatch_queue_create("com.example.MyCustomQueue", NULL);

     dispatch_async(myCustomQueue, ^{
         printf("Do some work here.\n");
     });

     printf("The first block may or may not have run.\n");

     dispatch_sync(myCustomQueue, ^{
         printf("Do some more work here.\n");
     });
     printf("Both blocks have completed.\n");
 }
 */

/*
 
 如何提高代码效率

 “西饼传说”
 代码设计优先级：系统方法 > 并行 > 串行 > 锁，简记为：西饼传说

 尽可能依赖 系统 框架。实现并发性的最佳方法是利用系统框架提供的内置并发性。
 尽早识别系列任务，并尽可能使它们更加 并行。如果因为某个任务依赖于某个共享资源而必须连续执行该任务，请考虑更改体系结构以删除该共享资源。您可以考虑为每个需要资源的客户机制作资源的副本，或者完全消除该资源。
 不使用锁来保护某些共享资源，而是指定一个 串行队列 (或使用操作对象依赖项)以正确的顺序执行任务。
 避免使用 锁。GCD 调度队列 和 操作队列 提供的支持使得在大多数情况下不需要锁定。
 确定操作对象的适当范围
 尽管可以向操作队列中添加任意大量的操作，但这样做通常是不切实际的。与任何对象一样，NSOperation 类的实例消耗内存，并且具有与其执行相关的实际成本。如果您的每个操作对象只执行少量的工作，并且您创建了数以万计的操作对象，那么您可能会发现，您花在调度操作上的时间比花在实际工作上的时间更多。如果您的应用程序已经受到内存限制，那么您可能会发现，仅仅在内存中拥有数万个操作对象就可能进一步降低性能。
 有效使用操作的关键是 在你需要做的工作量和保持计算机忙碌之间找到一个适当的平衡 。尽量确保你的业务做了合理的工作量。例如，如果您的应用程序创建了 100 个操作对象来对 100 个不同的值执行相同的任务，那么可以考虑创建 10 个操作对象来处理每个值。
 您还应该避免将大量操作一次性添加到队列中，或者避免连续地将操作对象添加到队列中的速度快于处理它们的速度。与其用操作对象淹没队列，不如批量创建这些对象。当一个批处理完成执行时，使用完成块告诉应用程序创建一个新的批处理。当您有很多工作要做时，您希望保持队列中充满足够的操作，以便计算机保持忙碌，但是您不希望一次创建太多操作，以至于应用程序耗尽内存。
 当然，您创建的操作对象的数量以及在每个操作对象中执行的工作量是可变的，并且完全取决于您的应用程序。你应该经常使用像 Instruments 这样的工具来帮助你在效率和速度之间找到一个适当的平衡。有关 Instruments 和其他可用于为代码收集度量标准的性能工具的概述，请参阅 性能概述。
 术语解释摘录

 异步任务（asynchronous tasks）：由一个线程启动，但实际上在另一个线程上运行，利用额外的处理器资源更快地完成工作。
 互斥（mutex）：提供对共享资源的互斥访问的锁。 互斥锁一次只能由一个线程持有。试图获取由不同线程持有的互斥对象会使当前线程处于休眠状态，直到最终获得锁为止。
 进程（process）：应用软件或程序的运行时实例。 进程有自己的虚拟内存空间和系统资源(包括端口权限) ，这些资源独立于分配给其他程序的资源。一个进程总是包含至少一个线程(主线程) ，并且可能包含任意数量的其他线程。
 信号量（semaphore）：限制对共享资源访问的受保护变量。 互斥（Mutexes）和条件（conditions）都是不同类型的信号量。
 任务（task），表示需要执行的工作量。
 线程（thread)：进程中的执行流程。 每个线程都有自己的堆栈空间，但在其他方面与同一进程中的其他线程共享内存。
 运行循环（run loop）: 一个事件处理循环， 接收事件并派发到适当的处理程序。
 
 */
