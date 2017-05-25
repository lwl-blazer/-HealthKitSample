//
//  ViewController.m
//  HealthKitSample
//
//  Created by blazer on 16/7/23.
//  Copyright © 2016年 blazer. All rights reserved.
//

#import "ViewController.h"
#import <HealthKit/HealthKit.h>
#import <CoreMotion/CoreMotion.h>

@interface ViewController ()

@property(nonatomic, strong) HKHealthStore *healthStore;

@property(nonatomic, strong) CMPedometer *pedometer;

@property(nonatomic, strong) UILabel *stepLabel;
@property(nonatomic, strong) UILabel *distanceLabel;
@property(nonatomic, strong) UIImageView *headImage;

@property(nonatomic, strong) CMMotionManager *motionManager;

@end

@implementation ViewController

- (HKHealthStore *)healthStore{
    if (_healthStore == nil) {
        _healthStore = [[HKHealthStore alloc] init];
    }
    return _healthStore;
}

- (CMPedometer *)pedometer{
    if (_pedometer == nil) {
        _pedometer = [[CMPedometer alloc] init];
    }
    return _pedometer;
}

- (UIImageView *)headImage{
    if (_headImage == nil) {
        _headImage = [[UIImageView alloc] initWithFrame:self.view.bounds];
        _headImage.image = [UIImage imageNamed:@"1.png"];
    }
    return _headImage;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self creatLocalView];
    [self initMotionManager];
    [self.view addSubview:self.headImage];
    // [self distanceProximityState];
}

- (void)creatLocalView{
    self.stepLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 84, 200, 40)];
    [self.stepLabel setTextColor:[UIColor blueColor]];
    self.stepLabel.text = @"步数:";
    [self.view addSubview:self.stepLabel];
    
    self.distanceLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(self.stepLabel.frame) + 10, 200, 40)];
    [self.distanceLabel setTextColor:[UIColor redColor]];
    self.distanceLabel.text = @"距离:";
    [self.view addSubview:self.distanceLabel];
    
    UIButton *rememberBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [rememberBtn setTitle:@"开始步行" forState:UIControlStateNormal];
    [rememberBtn setTitle:@"正在步行" forState:UIControlStateSelected];
    rememberBtn.frame = CGRectMake(0, 0, 100, 40);
    rememberBtn.center = self.view.center;
    [self.view addSubview:rememberBtn];
    [rememberBtn addTarget:self action:@selector(rememberBtnClick:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)rememberBtnClick:(UIButton *)sender{
    sender.selected = !sender.selected;
    if (self.pedometer == nil) {
        self.pedometer = [[CMPedometer alloc] init];
    }
    if (sender.selected) {
        [self initPedometer];
    }else{
        [self stopPedometer];
        if ([HKHealthStore isHealthDataAvailable]) {
            NSSet *writeDataTypes = [self dataTypesToWrite];
            NSSet *readDataTypes = [self dataTypesToRead];
            [self.healthStore requestAuthorizationToShareTypes:writeDataTypes readTypes:readDataTypes completion:^(BOOL success, NSError * _Nullable error) {
                if (!success) {
                    NSLog(@"获取数据不成功");
                }else{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self updateStepCountLabel];
                    });
                }
            }];
        }else{
            NSLog(@"不可以访问");
        }
    }
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

//写入数据类型
- (NSSet *)dataTypesToWrite{
    
    //HKQuantityTypeIdentifierDietaryEnergyConsumed 膳食能量
    HKQuantityType *dietaryCalorieEnergyType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryEnergyConsumed];
    
    //HKQuantityTypeIdentifierActiveEnergyBurned 活动能量
    HKQuantityType *activeEnergyBurnType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned];
    
    //HKQuantityTypeIdentifierHeight
    HKQuantityType *heightType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight];
    
    //HKQuantityTypeIdentifierBodyMass 体重
    HKQuantityType *weightType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
    
    //HKQuantityTypeIdentifierStepCount 步行数
    HKQuantityType *stepCountType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    
    return [NSSet setWithObjects:dietaryCalorieEnergyType, activeEnergyBurnType, heightType, weightType, stepCountType, nil];
}

//读取数据类型
- (NSSet *)dataTypesToRead{
    //HKQuantityTypeIdentifierDietaryEnergyConsumed 膳食能量
    HKQuantityType *dietaryCalorieEnergyType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryEnergyConsumed];
    
    //HKQuantityTypeIdentifierActiveEnergyBurned 活动能量
    HKQuantityType *activeEnergyBurnType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned];
    
    //HKQuantityTypeIdentifierHeight
    HKQuantityType *heightType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight];
    
    //HKQuantityTypeIdentifierBodyMass 体重
    HKQuantityType *weightType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
    
    //HKCharacteristicTypeIdentifierDateOfBirth 出生日期
    HKCharacteristicType *birthdayType = [HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierDateOfBirth];
    
    //HKCharacteristicTypeIdentifierBiologicalSex 性别
    HKCharacteristicType *biologicalSexType = [HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierBiologicalSex];
    
    //HKQuantityTypeIdentifierStepCount 步行数
    HKQuantityType *stepCountType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    
    return [NSSet setWithObjects:dietaryCalorieEnergyType, activeEnergyBurnType, heightType, weightType, birthdayType, biologicalSexType, stepCountType, nil];
}

#pragma mark --读取手机健康里面的数据
- (void)updateStepCountLabel{
    HKQuantityType *stepCountType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    
    //NSSortDescriptor用来告诉healthStore怎么样将结果排序
    NSSortDescriptor *start = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierStartDate ascending:NO];
    NSSortDescriptor *end = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierEndDate ascending:NO];
    
    //当天时间段
    NSPredicate *todayPredicate = [self predicateForSamplesToday];
    
    HKSampleQuery *sampleQuery = [[HKSampleQuery alloc] initWithSampleType:stepCountType predicate:todayPredicate limit:HKObjectQueryNoLimit sortDescriptors:@[start, end] resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
        NSLog(@"resultCount = %ld result = %@",results.count,results);
        /*数据格式
         result = (
         "190 count \"\U5065\U5eb7\" (9.3.2) metadata: {\n    HKWasUserEntered = 1;\n} 2016-07-23 14:34:00 +0800 2016-07-23 14:34:00 +0800",
         "80 count \"\U5065\U5eb7\" (9.3.2) metadata: {\n    HKWasUserEntered = 1;\n} 2016-07-23 14:30:00 +0800 2016-07-23 14:30:00 +0800"
         )
         
         数据内容分析
         result.quantity
         count:单位， 还有其它kg, m等，不同单位使用不同HKUnit
         \"\U5065\U5eb7\" reuslt.source.name
         (9.3.2)  result.device.softwareVersion App写入的时候是空的
         \"iPhone"\  result.device.model  有时候没有
         2016-07-23 14:34:00 +0800  result.startDate
         2016-07-23 14:34:00 +0800  result.endDate
         **/
        
        //手机自动计算步数
        double deviceStepCounts = 0.0f;
        //App写入的步数
        double appStepCounts = 0.0f;
        
        if (results.count == 0) {  //如果没有数据
            return ;
        }
        
        for (HKQuantitySample *result in results) {
            HKQuantity *quantity = result.quantity;
            HKUnit *stepCount = [HKUnit countUnit];
            double count = [quantity doubleValueForUnit:stepCount];
          
            //区分手机自动计算步数和App写入的步数
            //iOS9.0后 result.source.name 改成了 result.sourceRevision.source.name
            if ([result.sourceRevision.source.name isEqualToString:[UIDevice currentDevice].name]) {
                //App写入的数据reuslt.device.name为空
                if (result.device.name.length > 0) {
                    deviceStepCounts += count;
                }else{
                    appStepCounts +=count;
                }
            }else{
                appStepCounts += count;
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *deviceStepCountsString = [NSNumberFormatter localizedStringFromNumber:@(deviceStepCounts) numberStyle:NSNumberFormatterNoStyle];
            NSString *appStepCountsString = [NSNumberFormatter localizedStringFromNumber:@(appStepCounts) numberStyle:NSNumberFormatterNoStyle];
            NSString *totalCountsString = [NSNumberFormatter localizedStringFromNumber:@(deviceStepCounts + appStepCounts) numberStyle:NSNumberFormatterNoStyle];
            NSString *text = [NSString stringWithFormat:@"%@+%@=%@", deviceStepCountsString, appStepCountsString, totalCountsString];
            NSLog(@"%@", text);
            self.stepLabel.text = [NSString stringWithFormat:@"步数:%@", totalCountsString];
        });
        
    }];
    //执行查询
    [self.healthStore executeQuery:sampleQuery];
}

- (NSPredicate *)predicateForSamplesToday{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *now = [NSDate date];
    NSDate *startDate = [calendar startOfDayForDate:now];
    //加上一天
    NSDate *endDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:startDate options:0];
    return [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionStrictStartDate];
}


#pragma mark --写入步数数据
- (void)saveStepCountIntoHealthStore:(double)stepCount{
    HKUnit *countUnit = [HKUnit countUnit];
    HKQuantity *countUnitQuantity = [HKQuantity quantityWithUnit:countUnit doubleValue:stepCount];
    
    HKQuantityType *countUnitType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    NSDate *now = [NSDate date];
    HKQuantitySample *stepCountSample = [HKQuantitySample quantitySampleWithType:countUnitType quantity:countUnitQuantity startDate:now endDate:now];
    [self.healthStore saveObject:stepCountSample withCompletion:^(BOOL success, NSError * _Nullable error) {
        if (!success) {
            NSLog(@"写入失败");
            abort(); //界面会卡住感觉像卡死了一样，
        }else{
            NSLog(@"写入成功");
        }
    }];
}

//计步功能
/*
 要打开设备与健康的授权
 */
- (void)initPedometer{
    if ([CMPedometer isStepCountingAvailable]) {
        [self.pedometer startPedometerUpdatesFromDate:[NSDate date] withHandler:^(CMPedometerData * _Nullable pedometerData, NSError * _Nullable error) {
            if (error) {
                NSLog(@"计步error:%@", error);
            }else{
                NSLog(@"步数===%@", pedometerData.numberOfSteps);
                NSLog(@"距离%@", pedometerData.distance);
                self.distanceLabel.text = [NSString stringWithFormat:@"距离:%.0lfm", pedometerData.distance.floatValue];
                [self saveStepCountIntoHealthStore:pedometerData.numberOfSteps.doubleValue];
            }
        }];
    }
}

//停止计步数
- (void)stopPedometer{
    [self.pedometer stopPedometerUpdates];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark --CMMotionManager


- (void)initMotionManager{

    __weak typeof(self) weakSelf = self;
    self.motionManager = [[CMMotionManager alloc] init];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    //加速计（这是pull方式）
    if (self.motionManager.accelerometerAvailable) { //检查传感器在设备是否可用
        //更新的频率是10Hz   0.001=100Hz  Hz赫兹
        self.motionManager.accelerometerUpdateInterval = 0.01f;
        //加速计开始更新
        [self.motionManager startAccelerometerUpdatesToQueue:queue withHandler:^(CMAccelerometerData * _Nullable accelerometerData, NSError * _Nullable error) {
            NSString *labelText;
            if (error) {
                [self.motionManager stopAccelerometerUpdates];
                labelText = [NSString stringWithFormat:@"加速计失败:%@", error];
            }else{
                labelText = [NSString stringWithFormat:@":%.2f:%.2f+%.2f", accelerometerData.acceleration.x, accelerometerData.acceleration.y, accelerometerData.acceleration.z];
//                double rotation = atan2(accelerometerData.acceleration.x, accelerometerData.acceleration.y) - M_PI;
//                NSLog(@"%f", rotation);
//                blueView.transform = CGAffineTransformMakeRotation(rotation);
            }
            //waitUntilDone   是否等待
            //[self performSelectorOnMainThread:@selector(setTextLabel:) withObject:labelText waitUntilDone:NO]; //执行更新
            
            
/*
            //CMDeviceMotion是处理经过sensor fusing算法处理的Device Motion信息的提供，所attitude,gravity,userAcceleration,rotationRate数据进行封装
            CMDeviceMotion *deviceMotion = self.motionManager.deviceMotion;
            CMAttitude *referenceAttitude = deviceMotion.attitude;
            NSLog(@"1========pitch:%.2f roll:%.2f yaw:%.2f", referenceAttitude.pitch, referenceAttitude.roll, referenceAttitude.yaw);
            
            CMRotationMatrix rotation;
            CMAttitude *attitude = deviceMotion.attitude;
            if (referenceAttitude != nil) {
                [attitude multiplyByInverseOfAttitude:referenceAttitude];
            }
            rotation = attitude.rotationMatrix;
            NSLog(@"2=====pitch:%.2f roll:%.2f yaw:%.2f", rotation.m11, rotation.m12, rotation.m13);
 */
        }];
        
        //用一个NSTimer来进行读取数据  就是push方式
        //CMAccelerometerData *newesAccel = self.motionManager.accelerometerData;
        //获取数据
        //NSString *labelText = [NSString stringWithFormat:@":%.2f:%.2f+%.2f", newesAccel.acceleration.x, newesAccel.acceleration.y, newesAccel.acceleration.z];
        
        /*通过定义的CMAccelerometerData变量，获取CMAcceleration信息。CMAcceleration在Core Motion中是以结构体形式定义的：
        typedef struct{
          double x;
          double y;
          double z;
         }
         对应的motion信息，比如加速度或者旋转速度，就可以直接从这三个成员变量中得到
         */
        /*
         最后就是处理结束 释放资源
         //停止加速计的更新
         [self.motionManager stopAccelerometerUpdates];
         //停止陀螺仪的更新
         [self.motionManager stopGyroUpdates];
         //停止运动的传感器更新
         [self.motionManager stopDeviceMotionUpdates];
         */
        
        //获取加速器和陀螺仪的复合数据
        [self.motionManager startDeviceMotionUpdatesToQueue:queue withHandler:^(CMDeviceMotion * _Nullable motion, NSError * _Nullable error) {
            if (!error) {
                double rotation = atan2(motion.gravity.x, motion.gravity.y);
                weakSelf.headImage.transform = CGAffineTransformMakeRotation(rotation);
            }
        }];
        
        //这个方法是获取无损的陀螺仪数据
        //self.motionManager startGyroUpdatesToQueue:<#(nonnull NSOperationQueue *)#> withHandler:<#^(CMGyroData * _Nullable gyroData, NSError * _Nullable error)handler#>
    }else{
        NSLog(@"未授权");
    }
    
}

- (void)setTextLabel:(NSString *)string{
    NSLog(@"%@", string);
}


#pragma mark --距离传感器
- (void)distanceProximityState{
    //授权
    [UIDevice currentDevice].proximityMonitoringEnabled = YES;
    //监听有物品靠近还是离开
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(proximityStateDidChange) name:UIDeviceProximityStateDidChangeNotification object:nil];
}

- (void)proximityStateDidChange{
    if ([UIDevice currentDevice].proximityState) {
        NSLog(@"有物品靠近");
    }else{
        NSLog(@"有物品离开");
    }
}


//2016-07-23 17:15:49.158 HealthKitSample[3105:1584613] 105+480=585
@end
